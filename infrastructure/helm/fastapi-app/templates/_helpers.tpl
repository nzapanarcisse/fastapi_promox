{{- define "fastapi-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "fastapi-app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "fastapi-app.labels" -}}
helm.sh/chart: {{ include "fastapi-app.name" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: fastapi-app
{{- end }}

{{- define "fastapi-app.backendLabels" -}}
{{ include "fastapi-app.labels" . }}
app.kubernetes.io/name: fastapi-backend
app.kubernetes.io/component: backend
{{- end }}

{{- define "fastapi-app.frontendLabels" -}}
{{ include "fastapi-app.labels" . }}
app.kubernetes.io/name: fastapi-frontend
app.kubernetes.io/component: frontend
{{- end }}

{{- define "fastapi-app.adminerLabels" -}}
{{ include "fastapi-app.labels" . }}
app.kubernetes.io/name: fastapi-adminer
app.kubernetes.io/component: adminer
{{- end }}

