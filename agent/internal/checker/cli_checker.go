package checker

import (
	"fmt"
	"os/exec"
	"strings"
)

type CLITool struct {
	Name      string
	Command   string
	Installed bool
	Version   string
}

type CLIChecker struct {
	Tools map[string]*CLITool
}

func NewCLIChecker() *CLIChecker {
	return &CLIChecker{
		Tools: make(map[string]*CLITool),
	}
}

func (c *CLIChecker) CheckAll() {
	tools := []string{"aws", "terraform", "kubectl", "argocd", "git"}

	for _, tool := range tools {
		c.Tools[tool] = c.checkTool(tool)
	}
}

func (c *CLIChecker) checkTool(name string) *CLITool {
	tool := &CLITool{
		Name:      name,
		Command:   name,
		Installed: false,
		Version:   "",
	}

	// Check if command exists
	path, err := exec.LookPath(name)
	if err != nil {
		return tool
	}

	tool.Installed = true

	// Try to get version
	versionCmd := exec.Command(name, "--version")
	output, err := versionCmd.CombinedOutput()
	if err == nil {
		// Parse version from output (first line usually)
		lines := strings.Split(string(output), "\n")
		if len(lines) > 0 {
			tool.Version = strings.TrimSpace(lines[0])
		}
	}

	// Store full path
	tool.Command = path

	return tool
}

func (c *CLIChecker) GetStatus() string {
	var status strings.Builder
	status.WriteString("CLI Tools Status:\n")

	for name, tool := range c.Tools {
		if tool.Installed {
			status.WriteString(fmt.Sprintf("✅ %s: %s\n", name, tool.Version))
		} else {
			status.WriteString(fmt.Sprintf("❌ %s: Not installed\n", name))
		}
	}

	return status.String()
}

func (c *CLIChecker) IsInstalled(name string) bool {
	if tool, ok := c.Tools[name]; ok {
		return tool.Installed
	}
	return false
}
