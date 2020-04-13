package version

import (
	"fmt"
	"runtime"
)

var (
	appVersion = "v0.0.1"               // `git describe --tags --first-parent` or "v0.0.1" if not set
	gitCommit  = "no git"               // `git rev-parse HEAD` or "no git" if not set
	buildDate  = "1970-01-01T00:00:00Z" // `date -u +'%Y-%m-%dT%H:%M:%SZ'`, ISO8601 format
)

type BuildInfo struct {
	AppVersion string
	GitCommit  string
	BuildDate  string
	GoVersion  string
	Compiler   string
	Platform   string
}

func Get() *BuildInfo {
	return &BuildInfo{
		AppVersion: appVersion,
		GitCommit:  gitCommit,
		BuildDate:  buildDate,
		GoVersion:  runtime.Version(),
		Compiler:   runtime.Compiler,
		Platform:   fmt.Sprintf("%s/%s", runtime.GOOS, runtime.GOARCH),
	}
}
