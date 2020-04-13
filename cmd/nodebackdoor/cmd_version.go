package nodebackdoor

import (
	"github.com/spf13/cobra"
	"k8s.io/klog"

	"github.com/k8s-node-backdoor/pkg/version"
)

var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Show node backdoor client version",
	Run: func(cmd *cobra.Command, args []string) {
		v := version.Get()
		klog.Infof("App version: %s", v.AppVersion)
		klog.Infof("Git Commit: %s", v.GitCommit)
		klog.Infof("Build Date: %s", v.BuildDate)
		klog.Infof("Go Version: %s", v.GoVersion)
		klog.Infof("Compiler: %s", v.Compiler)
		klog.Infof("Platform: %s", v.Platform)
	},
}

func init() {
	RootCmd.AddCommand(versionCmd)
}
