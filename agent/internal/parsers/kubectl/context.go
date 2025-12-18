package kubectl

import (
	"encoding/json"
	"fmt"
	"os/exec"
	"strings"
)

// KubeContext represents a kubectl context
type KubeContext struct {
	Name      string `json:"name"`
	Cluster   string `json:"cluster"`
	User      string `json:"user"`
	Namespace string `json:"namespace"`
	Current   bool   `json:"current"`
}

// KubeCluster represents a cluster
type KubeCluster struct {
	Name   string `json:"name"`
	Server string `json:"server"`
}

// KubeNamespace represents a namespace
type KubeNamespace struct {
	Name   string `json:"name"`
	Status string `json:"status"`
}

// ListKubeContexts lists all kubectl contexts
func ListKubeContexts() ([]KubeContext, error) {
	cmd := exec.Command("kubectl", "config", "get-contexts", "-o", "json")
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to list contexts: %w", err)
	}

	var result struct {
		Contexts []struct {
			Name    string `json:"name"`
			Context struct {
				Cluster   string `json:"cluster"`
				User      string `json:"user"`
				Namespace string `json:"namespace"`
			} `json:"context"`
		} `json:"contexts"`
		CurrentContext string `json:"current-context"`
	}

	if err := json.Unmarshal(output, &result); err != nil {
		return nil, fmt.Errorf("failed to parse contexts: %w", err)
	}

	contexts := make([]KubeContext, 0, len(result.Contexts))
	for _, ctx := range result.Contexts {
		contexts = append(contexts, KubeContext{
			Name:      ctx.Name,
			Cluster:   ctx.Context.Cluster,
			User:      ctx.Context.User,
			Namespace: ctx.Context.Namespace,
			Current:   ctx.Name == result.CurrentContext,
		})
	}

	return contexts, nil
}

// GetCurrentContext gets the current kubectl context
func GetCurrentContext() (string, error) {
	cmd := exec.Command("kubectl", "config", "current-context")
	output, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("failed to get current context: %w", err)
	}

	return strings.TrimSpace(string(output)), nil
}

// SwitchContext switches to a different context
func SwitchContext(contextName string) error {
	cmd := exec.Command("kubectl", "config", "use-context", contextName)
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to switch context: %w", err)
	}

	return nil
}

// ListNamespaces lists all namespaces in current context
func ListNamespaces() ([]KubeNamespace, error) {
	cmd := exec.Command("kubectl", "get", "namespaces", "-o", "json")
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to list namespaces: %w", err)
	}

	var result struct {
		Items []struct {
			Metadata struct {
				Name string `json:"name"`
			} `json:"metadata"`
			Status struct {
				Phase string `json:"phase"`
			} `json:"status"`
		} `json:"items"`
	}

	if err := json.Unmarshal(output, &result); err != nil {
		return nil, fmt.Errorf("failed to parse namespaces: %w", err)
	}

	namespaces := make([]KubeNamespace, 0, len(result.Items))
	for _, ns := range result.Items {
		namespaces = append(namespaces, KubeNamespace{
			Name:   ns.Metadata.Name,
			Status: ns.Status.Phase,
		})
	}

	return namespaces, nil
}

// GetClusterInfo gets information about the current cluster
func GetClusterInfo() (map[string]interface{}, error) {
	cmd := exec.Command("kubectl", "cluster-info", "dump", "--output", "json")
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to get cluster info: %w", err)
	}

	var info map[string]interface{}
	if err := json.Unmarshal(output, &info); err != nil {
		return nil, fmt.Errorf("failed to parse cluster info: %w", err)
	}

	return info, nil
}

// GetPods gets pods in a namespace
func GetPods(namespace string) ([]map[string]interface{}, error) {
	args := []string{"get", "pods", "-o", "json"}
	if namespace != "" {
		args = append(args, "-n", namespace)
	} else {
		args = append(args, "--all-namespaces")
	}

	cmd := exec.Command("kubectl", args...)
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to get pods: %w", err)
	}

	var result struct {
		Items []map[string]interface{} `json:"items"`
	}

	if err := json.Unmarshal(output, &result); err != nil {
		return nil, fmt.Errorf("failed to parse pods: %w", err)
	}

	return result.Items, nil
}

// GetServices gets services in a namespace
func GetServices(namespace string) ([]map[string]interface{}, error) {
	args := []string{"get", "services", "-o", "json"}
	if namespace != "" {
		args = append(args, "-n", namespace)
	} else {
		args = append(args, "--all-namespaces")
	}

	cmd := exec.Command("kubectl", args...)
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to get services: %w", err)
	}

	var result struct {
		Items []map[string]interface{} `json:"items"`
	}

	if err := json.Unmarshal(output, &result); err != nil {
		return nil, fmt.Errorf("failed to parse services: %w", err)
	}

	return result.Items, nil
}
