{{/*
Expand the job definition.
*/}}
{{- define "mimir-provisioning.job" -}}
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ include "mimir-provisioning.fullname" . }}
  labels:
    {{- include "mimir-provisioning.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": post-install, post-upgrade
    "helm.sh/hook-weight": "-5"
spec:
  {{- include "mimir-provisioning.jobSpec" . | nindent 2 }}
{{- end }}

{{/*
Expand the job spec definition.
*/}}
{{- define "mimir-provisioning.jobSpec" -}}
backoffLimit: {{ .Values.backoffLimit }}
template:
  metadata:
    name: {{ printf "%s-%s" (include "mimir-provisioning.fullname" .) "provisioning" | trunc 63 | trimSuffix "-" }}
    labels:
      {{- include "mimir-provisioning.labels" . | nindent 4 }}
    {{- with .Values.podAnnotations }}
    annotations:
      {{- toYaml . | nindent 8 }}
    {{- end }}
  spec:
    {{- with .Values.imagePullSecrets }}
    imagePullSecrets:
      {{- toYaml . | nindent 8 }}
    {{- end }}
    serviceAccountName: {{ include "mimir-provisioning.serviceAccountName" . }}
    securityContext:
      {{- toYaml .Values.podSecurityContext | nindent 8 }}
    restartPolicy: OnFailure
    initContainers:
      - name: file-provisioner
        image: {{ .Values.sidecar.image.repository }}:{{ .Values.sidecar.image.tag }}
        securityContext:
          {{- toYaml .Values.sidecar.securityContext | nindent 12 }}
        imagePullPolicy: {{ .Values.sidecar.image.pullPolicy }}
        volumeMounts:
          - name: provisioning
            mountPath: /tmp/
        env: 
          - name: LABEL
            value: {{ .Values.sidecar.resourceLabel }}
          - name: FOLDER
            value: /tmp
          - name: RESOURCE
            value: {{ .Values.sidecar.resourceType }}
          - name: METHOD
            value: {{ .Values.sidecar.behaviour }}
          {{- if .Values.sidecar.extraEnvs }}
          {{ .Values.sidecar.extraEnvs | toYaml  | indent 12 | trim }}
          {{- end }}
        resources:
          {{- toYaml .Values.sidecar.resources | nindent 12 }}
    containers:
      - name: mimirtool
        image: {{ .Values.provisioner.image.repository }}:{{ .Values.provisioner.image.tag }}
        securityContext:
          {{- toYaml .Values.provisioner.securityContext | nindent 12 }}
        imagePullPolicy: {{ .Values.provisioner.image.pullPolicy }}
        env:
          - name: MIMIR_ADDRESS
            value: {{ .Values.provisioner.mimirAddress }}
          - name: MIMIR_TLS_INSECURE_SKIP_VERIFY
            value: {{ .Values.provisioner.mimirTLSInsecureSkipVerify | ternary "1" "0" | quote }}
        volumeMounts:
          - name: provisioning
            mountPath: /tmp/
          - name: provision-script
            mountPath: /script/mimirtool.sh
            subPath: mimirtool.sh
        command:
          - /script/mimirtool.sh
        resources:
          {{- toYaml .Values.provisioner.resources | nindent 12 }}
    {{- with .Values.nodeSelector }}
    nodeSelector:
      {{- toYaml . | nindent 8 }}
    {{- end }}
    {{- with .Values.affinity }}
    affinity:
      {{- toYaml . | nindent 8 }}
    {{- end }}
    {{- with .Values.tolerations }}
    tolerations:
      {{- toYaml . | nindent 8 }}
    {{- end }}
    volumes:
      - name: provisioning
        emptyDir: {}
      - name: provision-script
        configMap:
          name: {{ include "mimir-provisioning.provisionConfigmapName" . }}
          defaultMode: 0777
{{- end }}