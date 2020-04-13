package nodebackdoor

import (
	"flag"
	"fmt"

	sshbackdoor "github.com/k8s-node-backdoor/pkg/accessibility"
	"github.com/spf13/cobra"
	"k8s.io/klog"
)

type backdoorAccessibilityOptions struct {
	publicSSHFilepath  string
	authorizedKeysPath string
}

var (
	bao = &backdoorAccessibilityOptions{}
)

// RootCmd cobra init
var RootCmd = &cobra.Command{
	Use:   "nodebackdoor",
	Short: "Tooling for providing access to k8s-nodes for debugging purposes",
}

// Execute related to cobra init process
func Execute() {
	if err := RootCmd.Execute(); err != nil {
		fmt.Println(err)
		klog.Exit(err)
	}
}

var forwardSSHCmd = &cobra.Command{
	Use:   "forward-ssh",
	Short: "Forward ssh public key to node",
	Long:  `Write ssh public key to authorized hosts`,
	RunE: func(cmd *cobra.Command, args []string) error {
		return sshbackdoor.ForwardPublicKey(bao.publicSSHFilepath, bao.authorizedKeysPath)
	},
}

func init() {
	forwardSSHCmd.PersistentFlags().AddGoFlagSet(flag.CommandLine)
	// TODO use k8s secret instead of file
	forwardSSHCmd.PersistentFlags().StringVar(&bao.publicSSHFilepath, "public-key", "~/.ssh/id_rsa.pub", "Path to public ssh key")
	forwardSSHCmd.PersistentFlags().StringVar(&bao.authorizedKeysPath, "auth-keys", "~/.ssh/authorized_keys", "Path to ssh authorized keys file")
	RootCmd.AddCommand(forwardSSHCmd)
}
