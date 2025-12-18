package services

import (
	"os/exec"
	"runtime"
)

// SystemService handles system-related operations
type SystemService struct {
}

// NewSystemService creates a new system service
func NewSystemService() *SystemService {
	return &SystemService{}
}

// SystemDependency represents a system tool dependency
type SystemDependency struct {
	Name        string `json:"name"`
	Installed   bool   `json:"installed"`
	Path        string `json:"path"`
	InstallCmd  string `json:"install_cmd"`
	Description string `json:"description"`
}

// CheckDependencies checks for required system tools
func (s *SystemService) CheckDependencies() []SystemDependency {
	dependencies := []SystemDependency{
		{
			Name:        "nmap",
			Description: "Network exploration tool and security scanner",
			InstallCmd:  "brew install nmap",
		},
		{
			Name:        "dig",
			Description: "DNS lookup utility",
			InstallCmd:  "brew install bind", // 'dig' is in 'bind' package often, or 'bind-utils'
		},
		{
			Name:        "traceroute",
			Description: "Trace route to host",
			InstallCmd:  "brew install traceroute", // Often builtin but can be installed
		},
		{
			Name:        "whois",
			Description: "Domain whois lookup",
			InstallCmd:  "brew install whois",
		},
		{
			Name:        "openssl",
			Description: "TLS/SSL toolkit",
			InstallCmd:  "brew install openssl",
		},
		{
			Name:        "curl",
			Description: "Command line tool for transferring data",
			InstallCmd:  "brew install curl",
		},
		{
			Name:        "git",
			Description: "Version control system",
			InstallCmd:  "brew install git",
		},
		{
			Name:        "aws",
			Description: "AWS Command Line Interface",
			InstallCmd:  "brew install awscli",
		},
		{
			Name:        "terraform",
			Description: "Infrastructure as Code tool",
			InstallCmd:  "brew install terraform",
		},
		{
			Name:        "ansible",
			Description: "IT automation tool",
			InstallCmd:  "brew install ansible",
		},
		{
			Name:        "kubectl",
			Description: "Kubernetes command-line tool",
			InstallCmd:  "brew install kubectl",
		},
		{
			Name:        "helm",
			Description: "The Kubernetes Package Manager",
			InstallCmd:  "brew install helm",
		},
		{
			Name:        "docker",
			Description: "Container platform",
			InstallCmd:  "brew install --cask docker",
		},
		{
			Name:        "gcloud",
			Description: "Google Cloud SDK",
			InstallCmd:  "brew install --cask google-cloud-sdk",
		},
		{
			Name:        "az",
			Description: "Azure CLI",
			InstallCmd:  "brew install azure-cli",
		},
	}

	for i := range dependencies {
		path, err := exec.LookPath(dependencies[i].Name)
		if err == nil {
			dependencies[i].Installed = true
			dependencies[i].Path = path
			dependencies[i].InstallCmd = "" // Clear install cmd if installed
		} else {
			dependencies[i].Installed = false
			// Adjust install command based on OS if needed (focusing on Mac/Brew for now as per user env)
			if runtime.GOOS == "linux" {
				// Simple heuristic for common linux actions, though user is on Mac
				dependencies[i].InstallCmd = "sudo apt-get install " + dependencies[i].Name
			}
		}
	}

	return dependencies
}
