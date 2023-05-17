{{/*
Expand the name of the chart.
*/}}
{{- define "library-chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "library-chart.fullname" -}}
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

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "library-chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "library-chart.labels" -}}
helm.sh/chart: {{ include "library-chart.chart" . }}
{{ include "library-chart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.extraLabels}}
{{ toYaml .Values.extraLabels  }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "library-chart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "library-chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "library-chart.serviceAccountName" -}}
{{- if .Values.serviceAccount }}
{{- if .Values.serviceAccount.create }}
{{- if .Values.serviceAccount.name }}
{{- tpl .Values.serviceAccount.name . }}
{{- else }}
{{- include "library-chart.fullname" . }}
{{- end }}
{{- else if .Values.serviceAccount.useGlobal }}
{{- if .Values.global.serviceAccount.name }}
{{- tpl .Values.global.serviceAccount.name . }}
{{- else }}
{{- include "library-chart.fullname" . }}
{{- end }}
{{- end }}
{{- else if .Values.global }}
{{- if .Values.global.serviceAccount }}
{{- if .Values.global.serviceAccount.create }}
{{- if .Values.global.serviceAccount.name }}
{{- tpl .Values.global.serviceAccount.name . }}
{{- else }}
{{- include "library-chart.fullname" . }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}


{{- define "library-chart.globalContainerImage" }}
{{- default "docker.io" .Values.global.image.registry }}/{{  default .Chart.Name .Values.global.image.repository  }}:{{ default "latest" .Values.global.image.tag }}
{{- end }}

{{/*
Container image
*/}}
{{- define "library-chart.containerImage" -}}
{{- if and .Values.global .Values.global.image }}
{{- include "library-chart.globalContainerImage" . }}
{{- else if .Values.image }}
{{- default "docker.io"  .Values.image.registry }}/{{ default .Chart.Name .Values.image.repository }}:{{ default "latest" .Values.image.tag }}
{{- else }}
{{- "docker.io" }}/{{.Chart.Name }}:{{"latest" }}
{{- end }}

{{- end }}

{{- define "library-chart.jobContainerImage" -}}
{{- if and .Values.global .Values.global.image }}
{{- include "library-chart.globalContainerImage" . }}
{{- else  }}
{{- default "docker.io"  .Values.job.image.registry }}/{{ default .Chart.Name .Values.job.image.repository }}:{{ default "latest" .Values.job.image.tag }}
{{- end }}
{{- end }}

{{/*
service name 
*/}}
{{- define "library-chart.serviceName" -}}
{{- if .Values.service }}
name: {{ default ( include "library-chart.fullname" . )  .Values.service.name }}
{{- else }}
name: {{ default ( include "library-chart.fullname" . )  .Values.expose.name }}
{{- end }}
{{- end }}

{{/*
service type 
*/}}
{{- define "library-chart.serviceType" -}}
{{- if .Values.service }}
type: {{ default "ClusterIP" .Values.service.type }}
{{- else }}
type: {{ default "ClusterIP" .Values.expose.type }}
{{- end }}
{{- end }}

{{/*
service port 
*/}}
{{- define "library-chart.servicePorts" -}}
ports:
  {{- if .Values.service }}
  - name: {{ default "http"  .Values.service.portName }}
    port: {{ default 80  .Values.service.port }}
    protocol: {{ default "TCP" .Values.service.protocol }}
    {{- if  .Values.service.targetPort}}
    targetPort: {{ default 80  .Values.service.targetPort }}
    {{- else if and .Values.expose .Values.expose.port }}
    targetPort: {{ default 80  .Values.expose.port }}
    {{- end }}
  {{- else }}
  - name: {{ include  "library-chart.fullname"  . }}
    port: {{ default 80  .Values.expose.port }}
    protocol: {{ default "TCP" .Values.expose.protocol }}
    targetPort: {{ default 80  .Values.expose.port }}
  {{- end }}
{{- end }}

{{/*
Container image pull policy
*/}}
{{- define "library-chart.containerImagePullPolicy" -}}
{{- if .Values.image }}
{{- if .Values.image.pullPolicy }}
{{- .Values.image.pullPolicy }}
{{- else }}
{{- printf "IfNotPresent" }}
{{- end }}
{{- else if .Values.global }}
{{- if .Values.global.image }}
{{- if .Values.global.image.pullPolicy }}
{{- .Values.global.image.pullPolicy }}
{{- else }}
{{- printf "IfNotPresent" }}
{{- end }}
{{- else }}
{{- printf "Always" }}
{{- end }}
{{- end }}
{{- end }}


{{/*
Global environment variables
*/}}
{{- define "library-chart.globalEnvVars" }}
{{- if .Values.global }}
{{- if .Values.global.env }}
{{- range $key, $value := .Values.global.env }}
- name: {{ $key }}
  value: {{ tpl $value $ | quote }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{/*
Container environment variables
*/}}
{{- define "library-chart.containerEnvVars" }}
{{- include "library-chart.globalEnvVars" . }}
{{- if .Values.env }}
{{- if .Values.env.data }}
{{- range $key, $value := .Values.env.data }}
- name: {{ $key }}
  value: {{ tpl $value $ | quote }}
{{- end }}
{{- end }}
{{- end }}

{{- end }}


{{/*
Ingress hostname
*/}}
{{- define "library-chart.ingressHostname" -}}
{{- if ne .Values.envName "prod" }}
{{- if .Values.ingress.hostnameOverride }}
{{- printf "%s-%s.%s" .Values.envName .Values.ingress.hostnameOverride .Values.makeRealsDomain }}
{{- else }}
{{- printf "%s-%s.%s" .Values.envName .Chart.Name .Values.makeRealsDomain }}
{{- end }}
{{- else }}
{{- if .Values.ingress.hostnameOverride }}
{{- printf "%s.%s" .Values.ingress.hostnameOverride .Values.makeRealsDomain }}
{{- else }}
{{- printf "%s.%s" .Chart.Name .Values.makeRealsDomain }}
{{- end }}
{{- end }}
{{- end }}
