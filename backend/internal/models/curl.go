package models

// CurlRequest represents an advanced HTTP request using curl
type CurlRequest struct {
	Method          string            `json:"method"`
	URL             string            `json:"url"`
	Headers         map[string]string `json:"headers"`
	QueryParams     map[string]string `json:"query_params"`
	Body            string            `json:"body"`
	BodyType        string            `json:"body_type"` // json, xml, form, raw
	Auth            *AuthConfig       `json:"auth"`
	Timeout         int               `json:"timeout"`
	FollowRedirects bool              `json:"follow_redirects"`
	VerifySSL       bool              `json:"verify_ssl"`
	Verbose         bool              `json:"verbose"`
}

// AuthConfig represents authentication configuration
type AuthConfig struct {
	Type         string `json:"type"` // none, basic, bearer, apikey
	Username     string `json:"username"`
	Password     string `json:"password"`
	Token        string `json:"token"`
	ApiKey       string `json:"api_key"`
	ApiKeyHeader string `json:"api_key_header"`
}

// CurlResponse represents the response from a curl request
type CurlResponse struct {
	StatusCode    int                 `json:"status_code"`
	StatusText    string              `json:"status_text"`
	Headers       map[string][]string `json:"headers"`
	Body          string              `json:"body"`
	TimeMs        int64               `json:"time_ms"`
	ContentLength int64               `json:"content_length"`
	ContentType   string              `json:"content_type"`
	CurlCommand   string              `json:"curl_command"` // The generated curl command
}
