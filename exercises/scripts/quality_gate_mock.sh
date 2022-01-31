#!/bin/bash
keptn add-resource --project=easytravel --stage=production-disk --service=allproblems --resource=/home/$shell_user/perform-2022-hot-aiops/install/keptn/slo-unreal.yaml --resourceUri=slo.yaml
keptn configure monitoring dynatrace --project=easytravel

keptn trigger evaluation --project=easytravel --stage=production-disk --service=allproblems --timeframe=60m --labels=executedBy=manual
