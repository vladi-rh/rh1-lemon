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
