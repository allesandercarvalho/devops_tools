package aws

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// AWSConfig represents AWS configuration
type AWSConfig struct {
	Profiles map[string]Profile `json:"profiles"`
}

// Profile represents an AWS profile
type Profile struct {
	Name            string            `json:"name"`
	Region          string            `json:"region,omitempty"`
	Output          string            `json:"output,omitempty"`
	AccessKeyID     string            `json:"access_key_id,omitempty"`
	SecretAccessKey string            `json:"secret_access_key,omitempty"`
	SessionToken    string            `json:"session_token,omitempty"`
	RoleARN         string            `json:"role_arn,omitempty"`
	SourceProfile   string            `json:"source_profile,omitempty"`
	Extra           map[string]string `json:"extra,omitempty"`
}

// ParseAWSConfig reads and parses AWS config files
func ParseAWSConfig() (*AWSConfig, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return nil, err
	}

	configPath := filepath.Join(homeDir, ".aws", "config")
	credentialsPath := filepath.Join(homeDir, ".aws", "credentials")

	config := &AWSConfig{
		Profiles: make(map[string]Profile),
	}

	// Parse config file
	if err := parseConfigFile(configPath, config); err != nil {
		// Config file might not exist, that's okay
		if !os.IsNotExist(err) {
			return nil, err
		}
	}

	// Parse credentials file
	if err := parseCredentialsFile(credentialsPath, config); err != nil {
		// Credentials file might not exist, that's okay
		if !os.IsNotExist(err) {
			return nil, err
		}
	}

	return config, nil
}

// parseConfigFile parses ~/.aws/config
func parseConfigFile(path string, config *AWSConfig) error {
	file, err := os.Open(path)
	if err != nil {
		return err
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	var currentProfile string

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())

		// Skip empty lines and comments
		if line == "" || strings.HasPrefix(line, "#") || strings.HasPrefix(line, ";") {
			continue
		}

		// Profile header
		if strings.HasPrefix(line, "[") && strings.HasSuffix(line, "]") {
			profileName := strings.TrimSpace(line[1 : len(line)-1])

			// Remove "profile " prefix if present
			if strings.HasPrefix(profileName, "profile ") {
				profileName = strings.TrimSpace(profileName[8:])
			}

			currentProfile = profileName

			if _, exists := config.Profiles[currentProfile]; !exists {
				config.Profiles[currentProfile] = Profile{
					Name:  currentProfile,
					Extra: make(map[string]string),
				}
			}
			continue
		}

		// Key-value pair
		if currentProfile != "" && strings.Contains(line, "=") {
			parts := strings.SplitN(line, "=", 2)
			if len(parts) == 2 {
				key := strings.TrimSpace(parts[0])
				value := strings.TrimSpace(parts[1])

				profile := config.Profiles[currentProfile]

				switch key {
				case "region":
					profile.Region = value
				case "output":
					profile.Output = value
				case "role_arn":
					profile.RoleARN = value
				case "source_profile":
					profile.SourceProfile = value
				default:
					if profile.Extra == nil {
						profile.Extra = make(map[string]string)
					}
					profile.Extra[key] = value
				}

				config.Profiles[currentProfile] = profile
			}
		}
	}

	return scanner.Err()
}

// parseCredentialsFile parses ~/.aws/credentials
func parseCredentialsFile(path string, config *AWSConfig) error {
	file, err := os.Open(path)
	if err != nil {
		return err
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	var currentProfile string

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())

		// Skip empty lines and comments
		if line == "" || strings.HasPrefix(line, "#") || strings.HasPrefix(line, ";") {
			continue
		}

		// Profile header
		if strings.HasPrefix(line, "[") && strings.HasSuffix(line, "]") {
			currentProfile = strings.TrimSpace(line[1 : len(line)-1])

			if _, exists := config.Profiles[currentProfile]; !exists {
				config.Profiles[currentProfile] = Profile{
					Name:  currentProfile,
					Extra: make(map[string]string),
				}
			}
			continue
		}

		// Key-value pair
		if currentProfile != "" && strings.Contains(line, "=") {
			parts := strings.SplitN(line, "=", 2)
			if len(parts) == 2 {
				key := strings.TrimSpace(parts[0])
				value := strings.TrimSpace(parts[1])

				profile := config.Profiles[currentProfile]

				switch key {
				case "aws_access_key_id":
					profile.AccessKeyID = value
				case "aws_secret_access_key":
					profile.SecretAccessKey = value
				case "aws_session_token":
					profile.SessionToken = value
				default:
					if profile.Extra == nil {
						profile.Extra = make(map[string]string)
					}
					profile.Extra[key] = value
				}

				config.Profiles[currentProfile] = profile
			}
		}
	}

	return scanner.Err()
}

// WriteAWSConfig writes AWS config to files
func WriteAWSConfig(config *AWSConfig) error {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return err
	}

	awsDir := filepath.Join(homeDir, ".aws")

	// Create .aws directory if it doesn't exist
	if err := os.MkdirAll(awsDir, 0700); err != nil {
		return err
	}

	configPath := filepath.Join(awsDir, "config")
	credentialsPath := filepath.Join(awsDir, "credentials")

	// Write config file
	if err := writeConfigFile(configPath, config); err != nil {
		return err
	}

	// Write credentials file
	if err := writeCredentialsFile(credentialsPath, config); err != nil {
		return err
	}

	return nil
}

// writeConfigFile writes ~/.aws/config
func writeConfigFile(path string, config *AWSConfig) error {
	file, err := os.Create(path)
	if err != nil {
		return err
	}
	defer file.Close()

	for _, profile := range config.Profiles {
		// Write profile header
		if profile.Name == "default" {
			fmt.Fprintf(file, "[default]\n")
		} else {
			fmt.Fprintf(file, "[profile %s]\n", profile.Name)
		}

		// Write config values
		if profile.Region != "" {
			fmt.Fprintf(file, "region = %s\n", profile.Region)
		}
		if profile.Output != "" {
			fmt.Fprintf(file, "output = %s\n", profile.Output)
		}
		if profile.RoleARN != "" {
			fmt.Fprintf(file, "role_arn = %s\n", profile.RoleARN)
		}
		if profile.SourceProfile != "" {
			fmt.Fprintf(file, "source_profile = %s\n", profile.SourceProfile)
		}

		// Write extra fields
		for key, value := range profile.Extra {
			if key != "aws_access_key_id" && key != "aws_secret_access_key" && key != "aws_session_token" {
				fmt.Fprintf(file, "%s = %s\n", key, value)
			}
		}

		fmt.Fprintln(file)
	}

	return nil
}

// writeCredentialsFile writes ~/.aws/credentials
func writeCredentialsFile(path string, config *AWSConfig) error {
	file, err := os.Create(path)
	if err != nil {
		return err
	}
	defer file.Close()

	// Set restrictive permissions
	if err := os.Chmod(path, 0600); err != nil {
		return err
	}

	for _, profile := range config.Profiles {
		// Only write profiles that have credentials
		if profile.AccessKeyID == "" && profile.SecretAccessKey == "" {
			continue
		}

		// Write profile header
		fmt.Fprintf(file, "[%s]\n", profile.Name)

		// Write credentials
		if profile.AccessKeyID != "" {
			fmt.Fprintf(file, "aws_access_key_id = %s\n", profile.AccessKeyID)
		}
		if profile.SecretAccessKey != "" {
			fmt.Fprintf(file, "aws_secret_access_key = %s\n", profile.SecretAccessKey)
		}
		if profile.SessionToken != "" {
			fmt.Fprintf(file, "aws_session_token = %s\n", profile.SessionToken)
		}

		fmt.Fprintln(file)
	}

	return nil
}
