package collector

import (
	"log"
	"sync"
	"time"

	"github.com/devopstools/agent/internal/parsers/aws"
	"github.com/devopstools/agent/internal/parsers/kubectl"
	"github.com/devopstools/agent/internal/parsers/terraform"
)

// CollectedData represents aggregated data from all sources
type CollectedData struct {
	Timestamp  time.Time      `json:"timestamp"`
	AWS        AWSData        `json:"aws"`
	Terraform  TerraformData  `json:"terraform"`
	Kubernetes KubernetesData `json:"kubernetes"`
}

type AWSData struct {
	Stacks    []aws.CloudFormationStack `json:"stacks"`
	ECS       []aws.ECSCluster          `json:"ecs_clusters"`
	EKS       []aws.EKSCluster          `json:"eks_clusters"`
	LogGroups []aws.CloudWatchLogGroup  `json:"log_groups"`
}

type TerraformData struct {
	Workspaces []terraform.TerraformWorkspace `json:"workspaces"`
	State      *terraform.TerraformState      `json:"state,omitempty"`
}

type KubernetesData struct {
	Contexts   []kubectl.KubeContext   `json:"contexts"`
	Namespaces []kubectl.KubeNamespace `json:"namespaces"`
}

// Collector manages data collection
type Collector struct {
	mu sync.RWMutex
}

// NewCollector creates a new collector
func NewCollector() *Collector {
	return &Collector{}
}

// Collect gathers data from all sources
func (c *Collector) Collect() (*CollectedData, error) {
	c.mu.Lock()
	defer c.mu.Unlock()

	data := &CollectedData{
		Timestamp: time.Now(),
	}

	var wg sync.WaitGroup

	// AWS Collection
	wg.Add(1)
	go func() {
		defer wg.Done()
		// Use default profile for now, could be configurable
		profile := "default"

		stacks, err := aws.ListCloudFormationStacks(profile)
		if err != nil {
			log.Printf("⚠️ Failed to collect CloudFormation stacks: %v", err)
		} else {
			data.AWS.Stacks = stacks
		}

		ecs, err := aws.ListECSClusters(profile)
		if err != nil {
			log.Printf("⚠️ Failed to collect ECS clusters: %v", err)
		} else {
			data.AWS.ECS = ecs
		}

		eks, err := aws.ListEKSClusters(profile)
		if err != nil {
			log.Printf("⚠️ Failed to collect EKS clusters: %v", err)
		} else {
			data.AWS.EKS = eks
		}

		logs, err := aws.ListCloudWatchLogGroups(profile)
		if err != nil {
			log.Printf("⚠️ Failed to collect CloudWatch logs: %v", err)
		} else {
			data.AWS.LogGroups = logs
		}
	}()

	// Kubernetes Collection
	wg.Add(1)
	go func() {
		defer wg.Done()

		contexts, err := kubectl.ListKubeContexts()
		if err != nil {
			log.Printf("⚠️ Failed to collect Kube contexts: %v", err)
		} else {
			data.Kubernetes.Contexts = contexts
		}

		namespaces, err := kubectl.ListNamespaces()
		if err != nil {
			log.Printf("⚠️ Failed to collect Kube namespaces: %v", err)
		} else {
			data.Kubernetes.Namespaces = namespaces
		}
	}()

	// Terraform Collection (Current Directory)
	wg.Add(1)
	go func() {
		defer wg.Done()

		// TODO: Make this configurable or scan multiple directories
		workDir := "."

		workspaces, err := terraform.ListTerraformWorkspaces(workDir)
		if err != nil {
			// Terraform might not be initialized in current dir, which is fine
			// log.Printf("ℹ️ No Terraform workspaces found in %s", workDir)
		} else {
			data.Terraform.Workspaces = workspaces
		}

		// Try to parse state if it exists
		state, err := terraform.ParseTerraformState("terraform.tfstate")
		if err == nil {
			data.Terraform.State = state
		}
	}()

	wg.Wait()
	return data, nil
}
