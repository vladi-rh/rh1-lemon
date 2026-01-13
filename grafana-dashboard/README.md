# Grafana Setup

## Prerequisites 

- User workload monitoring needs to be enabled
- Grafana Operator have to be installed

### User workload monitoring
Check if ConfigMap already exists:
```bash
oc get configmap cluster-monitoring-config -n openshift-monitoring
```
and set `enableUserWorkload: true`.

Otherwise, create a ConfigMap as following:

```bash
oc create configmap cluster-monitoring-config \
  -n openshift-monitoring \
  --from-literal=config.yaml='enableUserWorkload: true' \
  --dry-run=client -o yaml | oc apply -f -
```

Verify monitoring pods are starting:
```bash
oc get pods -n openshift-user-workload-monitoring
NAME                                   READY   STATUS    RESTARTS   AGE
prometheus-operator-86bc45dcfb-6mclm   2/2     Running   0          37s
prometheus-user-workload-0             6/6     Running   0          35s
thanos-ruler-user-workload-0           4/4     Running   0          34s
```

# Grafana related resources

Currently all Grafana resources are "dumped" into `output.yaml`. 
Simple `oc apply -f output.yaml` will probably not work as there are interdependencies Grafana requires between CRs. (FIXME).

Once Grafana instance is up and running, the Dashboard might show "Datasource not found" error.
To fix this follow these steps:
. Enter edit mode for the whole dashboard (upper right corner button)
. In the "..." menu of the each of the panels, choose edit
.. click "run queries" (or wait for refresh) so that the panel shows the data
. repeat for the other remaining panels