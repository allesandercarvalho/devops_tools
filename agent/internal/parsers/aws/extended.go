package aws

import (
	"encoding/json"
	"fmt"
	"os/exec"
)

// CloudFormationStack represents a CloudFormation stack
type CloudFormationStack struct {
	StackName    string            `json:"stack_name"`
	StackID      string            `json:"stack_id"`
	Status       string            `json:"status"`
	CreationTime string            `json:"creation_time"`
	Parameters   map[string]string `json:"parameters"`
	Outputs      map[string]string `json:"outputs"`
	Tags         map[string]string `json:"tags"`
}

// ECSCluster represents an ECS cluster
type ECSCluster struct {
	ClusterName          string `json:"cluster_name"`
	ClusterArn           string `json:"cluster_arn"`
	Status               string `json:"status"`
	RegisteredContainers int    `json:"registered_containers"`
	RunningTasksCount    int    `json:"running_tasks_count"`
	PendingTasksCount    int    `json:"pending_tasks_count"`
	ActiveServicesCount  int    `json:"active_services_count"`
}

// EKSCluster represents an EKS cluster
type EKSCluster struct {
	Name     string            `json:"name"`
	Arn      string            `json:"arn"`
	Version  string            `json:"version"`
	Status   string            `json:"status"`
	Endpoint string            `json:"endpoint"`
	RoleArn  string            `json:"role_arn"`
	Tags     map[string]string `json:"tags"`
}

// CloudWatchLogGroup represents a CloudWatch log group
type CloudWatchLogGroup struct {
	LogGroupName      string `json:"log_group_name"`
	CreationTime      int64  `json:"creation_time"`
	RetentionInDays   int    `json:"retention_in_days"`
	StoredBytes       int64  `json:"stored_bytes"`
	MetricFilterCount int    `json:"metric_filter_count"`
}

// ListCloudFormationStacks lists all CloudFormation stacks
func ListCloudFormationStacks(profile string) ([]CloudFormationStack, error) {
	args := []string{"cloudformation", "describe-stacks"}
	if profile != "" {
		args = append(args, "--profile", profile)
	}
	args = append(args, "--output", "json")

	cmd := exec.Command("aws", args...)
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to list CloudFormation stacks: %w", err)
	}

	var result struct {
		Stacks []struct {
			StackName    string `json:"StackName"`
			StackID      string `json:"StackId"`
			StackStatus  string `json:"StackStatus"`
			CreationTime string `json:"CreationTime"`
			Parameters   []struct {
				ParameterKey   string `json:"ParameterKey"`
				ParameterValue string `json:"ParameterValue"`
			} `json:"Parameters"`
			Outputs []struct {
				OutputKey   string `json:"OutputKey"`
				OutputValue string `json:"OutputValue"`
			} `json:"Outputs"`
			Tags []struct {
				Key   string `json:"Key"`
				Value string `json:"Value"`
			} `json:"Tags"`
		} `json:"Stacks"`
	}

	if err := json.Unmarshal(output, &result); err != nil {
		return nil, fmt.Errorf("failed to parse CloudFormation stacks: %w", err)
	}

	stacks := make([]CloudFormationStack, 0, len(result.Stacks))
	for _, s := range result.Stacks {
		stack := CloudFormationStack{
			StackName:    s.StackName,
			StackID:      s.StackID,
			Status:       s.StackStatus,
			CreationTime: s.CreationTime,
			Parameters:   make(map[string]string),
			Outputs:      make(map[string]string),
			Tags:         make(map[string]string),
		}

		for _, p := range s.Parameters {
			stack.Parameters[p.ParameterKey] = p.ParameterValue
		}

		for _, o := range s.Outputs {
			stack.Outputs[o.OutputKey] = o.OutputValue
		}

		for _, t := range s.Tags {
			stack.Tags[t.Key] = t.Value
		}

		stacks = append(stacks, stack)
	}

	return stacks, nil
}

// ListECSClusters lists all ECS clusters
func ListECSClusters(profile string) ([]ECSCluster, error) {
	// First, list cluster ARNs
	args := []string{"ecs", "list-clusters"}
	if profile != "" {
		args = append(args, "--profile", profile)
	}
	args = append(args, "--output", "json")

	cmd := exec.Command("aws", args...)
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to list ECS clusters: %w", err)
	}

	var listResult struct {
		ClusterArns []string `json:"clusterArns"`
	}

	if err := json.Unmarshal(output, &listResult); err != nil {
		return nil, fmt.Errorf("failed to parse ECS cluster list: %w", err)
	}

	if len(listResult.ClusterArns) == 0 {
		return []ECSCluster{}, nil
	}

	// Describe clusters
	descArgs := []string{"ecs", "describe-clusters", "--clusters"}
	descArgs = append(descArgs, listResult.ClusterArns...)
	if profile != "" {
		descArgs = append(descArgs, "--profile", profile)
	}
	descArgs = append(descArgs, "--output", "json")

	descCmd := exec.Command("aws", descArgs...)
	descOutput, err := descCmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to describe ECS clusters: %w", err)
	}

	var descResult struct {
		Clusters []struct {
			ClusterName                  string `json:"clusterName"`
			ClusterArn                   string `json:"clusterArn"`
			Status                       string `json:"status"`
			RegisteredContainerInstances int    `json:"registeredContainerInstancesCount"`
			RunningTasksCount            int    `json:"runningTasksCount"`
			PendingTasksCount            int    `json:"pendingTasksCount"`
			ActiveServicesCount          int    `json:"activeServicesCount"`
		} `json:"clusters"`
	}

	if err := json.Unmarshal(descOutput, &descResult); err != nil {
		return nil, fmt.Errorf("failed to parse ECS cluster details: %w", err)
	}

	clusters := make([]ECSCluster, 0, len(descResult.Clusters))
	for _, c := range descResult.Clusters {
		clusters = append(clusters, ECSCluster{
			ClusterName:          c.ClusterName,
			ClusterArn:           c.ClusterArn,
			Status:               c.Status,
			RegisteredContainers: c.RegisteredContainerInstances,
			RunningTasksCount:    c.RunningTasksCount,
			PendingTasksCount:    c.PendingTasksCount,
			ActiveServicesCount:  c.ActiveServicesCount,
		})
	}

	return clusters, nil
}

// ListEKSClusters lists all EKS clusters
func ListEKSClusters(profile string) ([]EKSCluster, error) {
	// First, list cluster names
	args := []string{"eks", "list-clusters"}
	if profile != "" {
		args = append(args, "--profile", profile)
	}
	args = append(args, "--output", "json")

	cmd := exec.Command("aws", args...)
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to list EKS clusters: %w", err)
	}

	var listResult struct {
		Clusters []string `json:"clusters"`
	}

	if err := json.Unmarshal(output, &listResult); err != nil {
		return nil, fmt.Errorf("failed to parse EKS cluster list: %w", err)
	}

	clusters := make([]EKSCluster, 0, len(listResult.Clusters))
	for _, name := range listResult.Clusters {
		// Describe each cluster
		descArgs := []string{"eks", "describe-cluster", "--name", name}
		if profile != "" {
			descArgs = append(descArgs, "--profile", profile)
		}
		descArgs = append(descArgs, "--output", "json")

		descCmd := exec.Command("aws", descArgs...)
		descOutput, err := descCmd.Output()
		if err != nil {
			continue // Skip failed clusters
		}

		var descResult struct {
			Cluster struct {
				Name     string            `json:"name"`
				Arn      string            `json:"arn"`
				Version  string            `json:"version"`
				Status   string            `json:"status"`
				Endpoint string            `json:"endpoint"`
				RoleArn  string            `json:"roleArn"`
				Tags     map[string]string `json:"tags"`
			} `json:"cluster"`
		}

		if err := json.Unmarshal(descOutput, &descResult); err != nil {
			continue
		}

		clusters = append(clusters, EKSCluster{
			Name:     descResult.Cluster.Name,
			Arn:      descResult.Cluster.Arn,
			Version:  descResult.Cluster.Version,
			Status:   descResult.Cluster.Status,
			Endpoint: descResult.Cluster.Endpoint,
			RoleArn:  descResult.Cluster.RoleArn,
			Tags:     descResult.Cluster.Tags,
		})
	}

	return clusters, nil
}

// ListCloudWatchLogGroups lists CloudWatch log groups
func ListCloudWatchLogGroups(profile string) ([]CloudWatchLogGroup, error) {
	args := []string{"logs", "describe-log-groups"}
	if profile != "" {
		args = append(args, "--profile", profile)
	}
	args = append(args, "--output", "json")

	cmd := exec.Command("aws", args...)
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to list CloudWatch log groups: %w", err)
	}

	var result struct {
		LogGroups []struct {
			LogGroupName      string `json:"logGroupName"`
			CreationTime      int64  `json:"creationTime"`
			RetentionInDays   int    `json:"retentionInDays"`
			StoredBytes       int64  `json:"storedBytes"`
			MetricFilterCount int    `json:"metricFilterCount"`
		} `json:"logGroups"`
	}

	if err := json.Unmarshal(output, &result); err != nil {
		return nil, fmt.Errorf("failed to parse CloudWatch log groups: %w", err)
	}

	logGroups := make([]CloudWatchLogGroup, 0, len(result.LogGroups))
	for _, lg := range result.LogGroups {
		logGroups = append(logGroups, CloudWatchLogGroup{
			LogGroupName:      lg.LogGroupName,
			CreationTime:      lg.CreationTime,
			RetentionInDays:   lg.RetentionInDays,
			StoredBytes:       lg.StoredBytes,
			MetricFilterCount: lg.MetricFilterCount,
		})
	}

	return logGroups, nil
}

// GetResourceTags gets tags for an AWS resource
func GetResourceTags(resourceArn, profile string) (map[string]string, error) {
	args := []string{"resourcegroupstaggingapi", "get-resources", "--resource-arn-list", resourceArn}
	if profile != "" {
		args = append(args, "--profile", profile)
	}
	args = append(args, "--output", "json")

	cmd := exec.Command("aws", args...)
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to get resource tags: %w", err)
	}

	var result struct {
		ResourceTagMappingList []struct {
			Tags []struct {
				Key   string `json:"Key"`
				Value string `json:"Value"`
			} `json:"Tags"`
		} `json:"ResourceTagMappingList"`
	}

	if err := json.Unmarshal(output, &result); err != nil {
		return nil, fmt.Errorf("failed to parse resource tags: %w", err)
	}

	tags := make(map[string]string)
	if len(result.ResourceTagMappingList) > 0 {
		for _, tag := range result.ResourceTagMappingList[0].Tags {
			tags[tag.Key] = tag.Value
		}
	}

	return tags, nil
}

// SearchResourcesByTag searches for resources by tag
func SearchResourcesByTag(tagKey, tagValue, profile string) ([]string, error) {
	args := []string{"resourcegroupstaggingapi", "get-resources"}

	tagFilter := fmt.Sprintf("Key=%s,Values=%s", tagKey, tagValue)
	args = append(args, "--tag-filters", tagFilter)

	if profile != "" {
		args = append(args, "--profile", profile)
	}
	args = append(args, "--output", "json")

	cmd := exec.Command("aws", args...)
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to search resources by tag: %w", err)
	}

	var result struct {
		ResourceTagMappingList []struct {
			ResourceARN string `json:"ResourceARN"`
		} `json:"ResourceTagMappingList"`
	}

	if err := json.Unmarshal(output, &result); err != nil {
		return nil, fmt.Errorf("failed to parse resource search results: %w", err)
	}

	arns := make([]string, 0, len(result.ResourceTagMappingList))
	for _, resource := range result.ResourceTagMappingList {
		arns = append(arns, resource.ResourceARN)
	}

	return arns, nil
}
