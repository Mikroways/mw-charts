{{/*
Expand the cronjob definition.
*/}}
{{- define "mimir-provisioning.cronjob" -}}
apiVersion: batch/v1
kind: CronJob
metadata:
  name: {{ include "mimir-provisioning.fullname" . }}
  labels:
    {{- include "mimir-provisioning.labels" . | nindent 4 }}
spec:
  concurrencyPolicy: Forbid
  schedule: {{ .Values.cronjob.schedule }}
  jobTemplate:
    spec: {{- include "mimir-provisioning.jobSpec" . | nindent 6 }}
{{- end }}