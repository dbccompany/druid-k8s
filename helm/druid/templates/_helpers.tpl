{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "druid.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "druid.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "druid.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Monitoring volumes included in all Druid pods
*/}}
{{- define "monitoring.volumes" -}}
- name: {{ printf "%s-%s" .Release.Name "statsd" }}
  configMap:
    name: {{ printf "%s-%s" .Release.Name "statsd" }}
{{- end -}}

{{/*
Monitoring containers included in all Druid pods
*/}}
{{- define "monitoring.containers" -}}
{{- if .Values.global.monitoring.enabled }}
- name: statsd
  image: "{{ .Values.global.monitoring.image.repository }}:{{ .Values.global.monitoring.image.tag }}"
  imagePullPolicy: {{ .Values.global.monitoring.image.pullPolicy }}
  command: ["/bin/statsd_exporter"]
  args: ["--statsd.mapping-config=/etc/statsd_mapping.conf"]
  ports:
    - name: metrics
      containerPort: 9102
      protocol: TCP
    - name: statsd-udp
      containerPort: 9125
      protocol: UDP
    - name: statsd-tcp
      containerPort: 9125
      protocol: TCP
  livenessProbe:
    httpGet:
      path: /metrics
      port: metrics
  readinessProbe:
    httpGet:
      path: /metrics
      port: metrics
  volumeMounts:
  - name: {{ printf "%s-%s" .Release.Name "statsd" }}
    mountPath: /etc/statsd_mapping.conf
    subPath: statsd_mapping.conf
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "druid.serviceAccountName" -}}
{{- if .Values.global.serviceAccount.create }}
{{- default (include "druid.fullname" .) .Values.global.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.global.serviceAccount.name }}
{{- end }}
{{- end }}

