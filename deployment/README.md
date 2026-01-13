# Lemonade Stand - Guardrails Orchestrator Deployment

This guide walks you through deploying the Guardrails Orchestrator with LLM-D and content detectors on OpenShift AI.

## Prerequisites

### 0. NVidia GPU Operator

Successfully tested with NVidia GPU operator v25.10.0 (`gpu-operator-certified.v25.10.0`) with manual approval. 
The llama32 pod was Crash-looping with the newest operator (v25.10.1), therefore decision to pin the operator to the previous version.

### 1. Set TrustyAI ConfigMap to Unmanaged

Add the following annotation to the `trustyai-service-operator-config` ConfigMap in the `redhat-ods-applications` namespace:

```bash
oc annotate configmap trustyai-service-operator-config -n redhat-ods-applications opendatahub.io/managed='false'
```

### 2. Update the TrustyAI ConfigMap

Apply the updated ConfigMap with the required image configurations:

```bash
oc apply -f trustyai-service-operator-config.yaml
```

## Deployment Steps

### 3. Deploy the Components

Apply the YAML files in the following order:

#### MinIO Storage for Detector Models

```bash
oc new-project lemonade-stand
oc apply -f minio-storage-models.yaml
```

This deploys MinIO storage and downloads the detector models:
- `ibm-granite/granite-guardian-hap-125m` - HAP detection
- `protectai/deberta-v3-base-prompt-injection-v2` - Prompt injection detection
- `papluca/xlm-roberta-base-language-detection` - Language detection

#### Chunker Service

```bash
oc apply -f chunker.yaml
```

#### LLM-D with Llama 3.2 3B

```bash
oc apply -f llmd.yaml
```

This deploys:
- GatewayClass and Gateway for OpenShift AI inference
- `lemonade-stand` namespace
- LLMInferenceService with Llama 3.2 3B Instruct model

#### Detectors

```bash
oc apply -f ibm-hap-detector.yaml
oc apply -f prompt-injection-detector.yaml
oc apply -f language-detector.yaml
```

#### Guardrails Orchestrator Configuration

```bash
oc apply -f fms-orchestr8-config-nlp.yaml
```

#### Guardrails Orchestrator

```bash
oc apply -f guardrails-orchestrator.yaml
```

### 4. Update Configuration (Optional)

Update the config files as needed for your environment:
- Resource limits/requests
- Replica numbers
- Tolerations for GPU scheduling

## Testing the Deployment

### 5. Test the Configuration

Run the following commands to test your deployment:

```bash
export ORCH_ROUTE=$(oc get routes guardrails-orchestrator -n lemonade-stand -o jsonpath='{.spec.host}')

curl -X POST https://$ORCH_ROUTE/api/v2/chat/completions-detection \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "llama32",
    "messages": [
      {
        "role": "user",
        "content": "hello"
      }
    ],
    "stream": true,
    "detectors": {
      "input": {
        "regex_competitor": {},
        "hap": {},
        "prompt_injection": {},
        "language_detection": {}
      },
      "output": {
        "regex_competitor": {},
        "hap": {},
        "language_detection": {}
      }
    }
  }'
```

## Deploy Frontend

### 6. Deploy the Gradio Frontend Application

Once the orchestrator is working correctly, deploy the frontend:

```bash
oc apply -f ../lemonade-stand-app/openshift-deployment.yaml -n lemonade-stand
```

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         lemonade-stand namespace                        │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────┐      ┌──────────────────────────────────────────┐  │
│  │  Gradio Frontend│─────▶│     Guardrails Orchestrator              │  │
│  └─────────────────┘      └──────────────────────────────────────────┘  │
│                                        │                                │
│                    ┌───────────────────┼───────────────────┐            │
│                    │                   │                   │            │
│                    ▼                   ▼                   ▼            │
│  ┌─────────────────────┐  ┌─────────────────┐  ┌────────────────────┐   │
│  │    HAP Detector     │  │ Prompt Injection│  │ Language Detector  │   │
│  │ (granite-guardian)  │  │    Detector     │  │ (xlm-roberta)      │   │
│  └─────────────────────┘  └─────────────────┘  └────────────────────┘   │
│                                                                         │
│  ┌─────────────────────┐  ┌─────────────────┐                           │
│  │   Chunker Service   │  │    LLM-D        │                           │
│  │                     │  │ (Llama 3.2 3B)  │                           │
│  └─────────────────────┘  └─────────────────┘                           │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │                    MinIO Storage (Detector Models)              │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

## Files Reference

| File | Description |
|------|-------------|
| `trustyai-service-operator-config.yaml` | TrustyAI operator ConfigMap with custom images |
| `minio-storage-models.yaml` | MinIO storage with detector models |
| `chunker.yaml` | Chunker service for text segmentation |
| `llmd.yaml` | LLM-D with Llama 3.2 3B Instruct |
| `ibm-hap-detector.yaml` | IBM HAP (Hate, Abuse, Profanity) detector |
| `prompt-injection-detector.yaml` | Prompt injection detector |
| `language-detector.yaml` | Language detection detector |
| `fms-orchestr8-config-nlp.yaml` | Orchestrator configuration |
| `guardrails-orchestrator.yaml` | Guardrails Orchestrator CR |


Note: inference gateway: 20 replicas