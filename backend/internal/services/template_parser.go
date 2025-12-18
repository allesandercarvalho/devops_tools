package services

import (
	"regexp"
	"strings"
)

type TemplateParser struct {
	variablePattern *regexp.Regexp
}

func NewTemplateParser() *TemplateParser {
	return &TemplateParser{
		variablePattern: regexp.MustCompile(`\{([A-Z_][A-Z0-9_]*)\}`),
	}
}

// ExtractVariables extracts all variable names from a command template
// Example: "aws ec2 run-instances --image-id {AMI_ID} --instance-type {INSTANCE_TYPE}"
// Returns: ["AMI_ID", "INSTANCE_TYPE"]
func (tp *TemplateParser) ExtractVariables(command string) []string {
	matches := tp.variablePattern.FindAllStringSubmatch(command, -1)

	// Use map to deduplicate
	seen := make(map[string]bool)
	variables := make([]string, 0)

	for _, match := range matches {
		if len(match) > 1 {
			varName := match[1]
			if !seen[varName] {
				seen[varName] = true
				variables = append(variables, varName)
			}
		}
	}

	return variables
}

// SubstituteVariables replaces variable placeholders with actual values
// Example: "aws ec2 run-instances --image-id {AMI_ID}" with {"AMI_ID": "ami-12345"}
// Returns: "aws ec2 run-instances --image-id ami-12345"
func (tp *TemplateParser) SubstituteVariables(command string, variables map[string]string) string {
	result := command

	for key, value := range variables {
		placeholder := "{" + key + "}"
		result = strings.ReplaceAll(result, placeholder, value)
	}

	return result
}

// ValidateCommand checks if all variables in the command have values
// Returns list of missing variables
func (tp *TemplateParser) ValidateCommand(command string, variables map[string]string) []string {
	required := tp.ExtractVariables(command)
	missing := make([]string, 0)

	for _, varName := range required {
		if _, ok := variables[varName]; !ok {
			missing = append(missing, varName)
		}
	}

	return missing
}

// PreviewCommand shows the command with variables substituted and highlights missing ones
func (tp *TemplateParser) PreviewCommand(command string, variables map[string]string) string {
	result := command

	for key, value := range variables {
		placeholder := "{" + key + "}"
		if value != "" {
			result = strings.ReplaceAll(result, placeholder, value)
		}
	}

	return result
}
