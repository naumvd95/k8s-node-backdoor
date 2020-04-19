package nodebackdoor

import (
	"errors"
	"flag"
	"fmt"
	"os"

	"github.com/spf13/cobra"
	"k8s.io/klog"

	sshbackdoor "github.com/naumvd95/k8s-node-backdoor/pkg/accessibility"
	logging "github.com/naumvd95/k8s-node-backdoor/pkg/logging"
)

type backdoorLoggingOptions struct {
	enabled           bool
	logsInputPath     string
	logsOutputPath    string
	logsArchivePrefix string
}

type backdoorAccessibilityOptions struct {
	enabled            bool
	publicSSHFilepath  string
	authorizedKeysPath string
}

type daemonScenarioOptions struct {
	forwardSSH  backdoorAccessibilityOptions
	collectLogs backdoorLoggingOptions
}

var (
	dso = &daemonScenarioOptions{}
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

var daemonCmd = &cobra.Command{
	Use:   "daemon",
	Short: "Run all backdoor operations in daemon mode",
	Long:  `Run all backdoor operations in daemon mode, arguments managed by ENV variables`,
	Run: func(cmd *cobra.Command, args []string) {
		scenario, err := validateEnv(dso)
		if err != nil {
			klog.Exit(err)
		}

		if scenario.forwardSSH.enabled {
			err = sshbackdoor.ForwardPublicKey(scenario.forwardSSH.publicSSHFilepath,
				scenario.forwardSSH.authorizedKeysPath)
			if err != nil {
				klog.Exit(err)
			}
		}
		if scenario.collectLogs.enabled {
			err = logging.PackLogs(scenario.collectLogs.logsInputPath,
				scenario.collectLogs.logsOutputPath,
				scenario.collectLogs.logsArchivePrefix)
			if err != nil {
				klog.Exit(err)
			}
		}
	},
}

func validateEnv(scenario *daemonScenarioOptions) (*daemonScenarioOptions, error) {
	var defined bool
	if scenario.forwardSSH.enabled {
		scenario.forwardSSH.authorizedKeysPath, defined = os.LookupEnv("AUTHORIZED_KEYS_PATH")
		if !defined {
			return scenario, errors.New("AUTHORIZED_KEYS_PATH is not set, public key forwading is not possible")
		}
		scenario.forwardSSH.publicSSHFilepath, defined = os.LookupEnv("PUBLIC_KEY_PATH")
		if !defined {
			return scenario, errors.New("PUBLIC_KEY_PATH is not set, public key forwading is not possible")
		}
	}

	if scenario.collectLogs.enabled {
		scenario.collectLogs.logsInputPath, defined = os.LookupEnv("LOGS_INPUT_PATH")
		if !defined {
			return scenario, errors.New("LOGS_INPUT_PATH is not set, log collecting is not possible")
		}
		scenario.collectLogs.logsOutputPath, defined = os.LookupEnv("LOGS_OUTPUT_PATH")
		if !defined {
			return scenario, errors.New("LOGS_OUTPUT_PATH is not set, log collecting is not possible")
		}
		scenario.collectLogs.logsArchivePrefix, defined = os.LookupEnv("LOGS_ARCHIVE_PREFIX")
		if !defined {
			scenario.collectLogs.logsArchivePrefix = "nodebackdoor-log-pack"
			klog.Warning("LOGS_ARCHIVE_PREFIX is not set, using default one: nodebackdoor-log-pack")
		}
	}

	return scenario, nil
}

func init() {
	daemonCmd.PersistentFlags().AddGoFlagSet(flag.CommandLine)
	// TODO use k8s secret for ssh pubkey instead of file
	daemonCmd.PersistentFlags().BoolVar(&dso.forwardSSH.enabled, "forward-ssh",
		false, "Forward ssh public key to node, required: AUTHORIZED_KEYS_PATH, PUBLIC_KEY_PATH")
	daemonCmd.PersistentFlags().BoolVar(&dso.collectLogs.enabled, "collect-logs",
		false, "Pack logs in archives periodically to allow direct downloading, required: LOGS_INPUT_PATH, LOGS_OUTPUT_PATH")

	RootCmd.AddCommand(daemonCmd)
}
