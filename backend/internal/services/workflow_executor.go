package services

import (
	"bufio"
	"context"
	"fmt"
	"os/exec"
	"regexp"
	"strings"
	"time"

	"github.com/devopstools/backend/internal/models"
	"github.com/google/uuid"
)

type WorkflowExecutor struct {
	store           *WorkflowStore
	variableService *VariableService
	templateParser  *TemplateParser
}

func NewWorkflowExecutor(store *WorkflowStore, variableService *VariableService) *WorkflowExecutor {
	return &WorkflowExecutor{
		store:           store,
		variableService: variableService,
		templateParser:  NewTemplateParser(),
	}
}

func (e *WorkflowExecutor) Execute(ctx context.Context, workflowID string, inputs map[string]string, outputChan chan<- string) (*models.WorkflowExecution, error) {
	workflow, err := e.store.Get(workflowID)
	if err != nil {
		return nil, err
	}

	execution := &models.WorkflowExecution{
		ID:         uuid.New().String(),
		WorkflowID: workflowID,
		Status:     "running",
		Variables:  make(map[string]string),
		Logs:       []models.ExecutionLog{},
		StartTime:  time.Now().Format(time.RFC3339),
	}

	// Merge global variables first
	globalVars := e.variableService.GetAll()
	for k, v := range globalVars {
		execution.Variables[k] = v
	}

	// Merge workflow default values
	for _, v := range workflow.Variables {
		if _, ok := execution.Variables[v.Name]; !ok && v.DefaultValue != "" {
			execution.Variables[v.Name] = v.DefaultValue
		}
	}

	// Override with user inputs
	for k, v := range inputs {
		execution.Variables[k] = v
	}

	go func() {
		defer close(outputChan)

		e.logInfo(outputChan, execution, "", fmt.Sprintf("Starting workflow: %s", workflow.Name))

		currentStepIndex := 0
		for currentStepIndex < len(workflow.Steps) {
			step := workflow.Steps[currentStepIndex]

			select {
			case <-ctx.Done():
				e.logInfo(outputChan, execution, step.ID, "Execution cancelled")
				execution.Status = "cancelled"
				execution.EndTime = time.Now().Format(time.RFC3339)
				return
			default:
			}

			e.logInfo(outputChan, execution, step.ID, fmt.Sprintf("Step %d/%d: %s", currentStepIndex+1, len(workflow.Steps), step.Name))

			var stepErr error
			var output string
			var exitCode int

			switch step.Type {
			case "command":
				output, exitCode, stepErr = e.executeCommandStep(ctx, step, execution.Variables, outputChan, execution)
			case "workflow_ref":
				stepErr = e.executeWorkflowStep(ctx, step, execution.Variables, outputChan, execution)
			default:
				stepErr = fmt.Errorf("unknown step type: %s", step.Type)
			}

			// Check conditions
			if len(step.Conditions) > 0 {
				action := e.evaluateConditions(step.Conditions, output, exitCode)
				if action != nil {
					e.logInfo(outputChan, execution, step.ID, fmt.Sprintf("Condition matched: %s", action.Type))

					switch action.Type {
					case "stop":
						execution.Status = "completed"
						execution.EndTime = time.Now().Format(time.RFC3339)
						e.logInfo(outputChan, execution, "", "Workflow stopped by condition")
						return
					case "jump_to":
						// Find target step
						for i, s := range workflow.Steps {
							if s.ID == action.Target {
								currentStepIndex = i
								e.logInfo(outputChan, execution, step.ID, fmt.Sprintf("Jumping to step: %s", s.Name))
								continue
							}
						}
					case "execute_step":
						// Execute specific step and continue
						for _, s := range workflow.Steps {
							if s.ID == action.Target {
								e.logInfo(outputChan, execution, step.ID, fmt.Sprintf("Executing step: %s", s.Name))
								e.executeCommandStep(ctx, s, execution.Variables, outputChan, execution)
								break
							}
						}
					}
				}
			}

			// Handle step result
			if stepErr != nil {
				e.logError(outputChan, execution, step.ID, fmt.Sprintf("Step failed: %v", stepErr))

				if step.OnFailure != nil {
					e.handleStepAction(step.OnFailure, workflow.Steps, &currentStepIndex, outputChan, execution)
				} else {
					execution.Status = "failed"
					execution.EndTime = time.Now().Format(time.RFC3339)
					return
				}
			} else {
				if step.OnSuccess != nil {
					e.handleStepAction(step.OnSuccess, workflow.Steps, &currentStepIndex, outputChan, execution)
				}
			}

			currentStepIndex++
		}

		execution.Status = "completed"
		execution.EndTime = time.Now().Format(time.RFC3339)
		e.logInfo(outputChan, execution, "", "Workflow completed successfully")
	}()

	return execution, nil
}

func (e *WorkflowExecutor) executeCommandStep(ctx context.Context, step models.Step, variables map[string]string, outputChan chan<- string, execution *models.WorkflowExecution) (string, int, error) {
	// Substitute variables
	command := e.templateParser.SubstituteVariables(step.Content, variables)

	// Handle step-specific variable mappings
	for key, valName := range step.Variables {
		if val, ok := variables[valName]; ok {
			command = strings.ReplaceAll(command, fmt.Sprintf("{%s}", key), val)
		}
	}

	e.logInfo(outputChan, execution, step.ID, fmt.Sprintf("$ %s", command))

	// Execute
	cmd := exec.CommandContext(ctx, "sh", "-c", command)

	stdout, _ := cmd.StdoutPipe()
	stderr, _ := cmd.StderrPipe()

	if err := cmd.Start(); err != nil {
		return "", -1, err
	}

	var output strings.Builder

	// Stream output
	go func() {
		scanner := bufio.NewScanner(stdout)
		for scanner.Scan() {
			line := scanner.Text()
			output.WriteString(line + "\n")
			e.logInfo(outputChan, execution, step.ID, line)
		}
	}()

	go func() {
		scanner := bufio.NewScanner(stderr)
		for scanner.Scan() {
			line := scanner.Text()
			output.WriteString(line + "\n")
			e.logError(outputChan, execution, step.ID, line)
		}
	}()

	err := cmd.Wait()
	exitCode := 0
	if err != nil {
		if exitErr, ok := err.(*exec.ExitError); ok {
			exitCode = exitErr.ExitCode()
		} else {
			exitCode = -1
		}
	}

	return output.String(), exitCode, err
}

func (e *WorkflowExecutor) executeWorkflowStep(ctx context.Context, step models.Step, variables map[string]string, outputChan chan<- string, execution *models.WorkflowExecution) error {
	e.logInfo(outputChan, execution, step.ID, fmt.Sprintf("Executing sub-workflow: %s", step.Content))

	// Create sub-execution channel
	subOutputChan := make(chan string, 100)

	// Forward sub-workflow logs
	go func() {
		for msg := range subOutputChan {
			e.logInfo(outputChan, execution, step.ID, "  "+msg)
		}
	}()

	// Execute sub-workflow
	_, err := e.Execute(ctx, step.Content, variables, subOutputChan)
	return err
}

func (e *WorkflowExecutor) evaluateConditions(conditions []models.Condition, output string, exitCode int) *models.StepAction {
	for _, cond := range conditions {
		matched := false

		switch cond.Type {
		case "contains":
			matched = strings.Contains(output, cond.Value)
		case "equals":
			matched = strings.TrimSpace(output) == cond.Value
		case "starts_with":
			matched = strings.HasPrefix(strings.TrimSpace(output), cond.Value)
		case "ends_with":
			matched = strings.HasSuffix(strings.TrimSpace(output), cond.Value)
		case "regex":
			if re, err := regexp.Compile(cond.Value); err == nil {
				matched = re.MatchString(output)
			}
		case "exit_code":
			matched = fmt.Sprintf("%d", exitCode) == cond.Value
		}

		if matched {
			return &cond.Action
		}
	}

	return nil
}

func (e *WorkflowExecutor) handleStepAction(action *models.StepAction, steps []models.Step, currentIndex *int, outputChan chan<- string, execution *models.WorkflowExecution) {
	switch action.Type {
	case "continue":
		// Do nothing, continue to next step
	case "stop":
		*currentIndex = len(steps) // Force loop to end
	case "jump_to":
		for i, s := range steps {
			if s.ID == action.Target {
				*currentIndex = i - 1 // -1 because loop will increment
				break
			}
		}
	}
}

func (e *WorkflowExecutor) logInfo(outputChan chan<- string, execution *models.WorkflowExecution, stepID, message string) {
	outputChan <- message
	if execution != nil {
		execution.Logs = append(execution.Logs, models.ExecutionLog{
			Timestamp: time.Now().Format(time.RFC3339),
			StepID:    stepID,
			Level:     "info",
			Message:   message,
		})
	}
}

func (e *WorkflowExecutor) logError(outputChan chan<- string, execution *models.WorkflowExecution, stepID, message string) {
	outputChan <- message
	if execution != nil {
		execution.Logs = append(execution.Logs, models.ExecutionLog{
			Timestamp: time.Now().Format(time.RFC3339),
			StepID:    stepID,
			Level:     "error",
			Message:   message,
		})
	}
}
