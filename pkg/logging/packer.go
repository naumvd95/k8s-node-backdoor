package logging

import (
	"fmt"
	"os"
	"path/filepath"
	"time"

	"github.com/pkg/errors"

	"github.com/walle/targz"
	"k8s.io/apimachinery/pkg/util/wait"
	"k8s.io/klog"
)

//PackLogs collect logs in archives store in desired place
func PackLogs(from, to, frequency, archivePrefix string) error {
	klog.Info("Starting log collector procedure")
	interval, err := time.ParseDuration(frequency)
	if err != nil {
		return err
	}

	logsIteration := 1
	var archiveName string
	err = wait.PollImmediateInfinite(interval, func() (bool, error) {
		_, err := os.Stat(from)
		if os.IsNotExist(err) {
			return false, err
		}
		archiveName = fmt.Sprintf("%s_%v.tar.gz", archivePrefix, logsIteration)
		// TODO find a way to get external node ip
		nodeIP, defined := os.LookupEnv("NODE_IP")
		if !defined {
			klog.Warning("Can't detect external node ip to generate log scp url")
			nodeIP = "EXTERNAL_NODE_IP"
		}

		klog.Infof("Packing as %s", archiveName)
		err = targz.Compress(from, filepath.Join(to, archiveName))
		if err != nil {
			return false, err
		}

		klog.Infof("Log accessible via: scp ubuntu@%s:%s /tmp/", nodeIP, filepath.Join(to, archiveName))
		logsIteration++
		return false, nil
	})
	if err != nil {
		return errors.Wrap(err, "failed to collect logs")
	}

	return nil
}
