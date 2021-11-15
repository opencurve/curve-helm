{{/*
Expand the name of the chart.
*/}}
{{- define "chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
Rendering template
*/}}
{{- define "helm-toolkit.utils.template" -}}
{{- $name := index . 0 -}}
{{- $context := index . 1 -}}
{{- $last := base $context.Template.Name }}
{{- $wtf := $context.Template.Name | replace $last $name -}}
{{ include $wtf $context }}
{{- end -}}


{{/*
Metadata labels
*/}}
{{- define "helm-toolkit.utils.metadataLabels" -}}
{{- $g_role := index . 0 -}}
{{- $G := index . 1 -}}
helm.sh/chart: {{ $G.Chart.Name }}-{{ $G.Chart.Version | replace "+"  "_" }}
app.kubernetes.io/name: {{ template "chart.name" $G }}
app.kubernetes.io/instance: {{ $G.Release.Name }}
app.kubernetes.io/component: {{ $g_role }}
app.kubernetes.io/managed-by: curve-helm
{{- end }}


{{/*
Selector labels
*/}}
{{- define "helm-toolkit.utils.selectorLabels" -}}
{{- $g_role := index . 0 -}}
{{- $G := index . 1 -}}
app.kubernetes.io/name: {{ template "chart.name" $G }}
app.kubernetes.io/instance: {{ $G.Release.Name }}
app.kubernetes.io/component: {{ $g_role }}
app.kubernetes.io/managed-by: curve-helm
{{- end }}


{{/*
Cluster etcd address
*/}}
{{- define "helm-toolkit.curvefs.clusterEtcdAddr" -}}
{{- $G := . }}
{{- range $i, $_ := until (.Values.etcd.replicas | int) -}}
{{ if ne $i 0 }},{{ end }}etcd-{{ $i }}.etcd-service.{{ $G.Release.Namespace }}:{{ $G.Values.etcd.clientPort }}
{{- end }}
{{- end }}


{{/*
Cluster etcd http address
*/}}
{{- define "helm-toolkit.curvefs.clusterEtcdHttpAddr" -}}
{{- $G := . }}
{{- range $i, $_ := until (.Values.etcd.replicas | int) -}}
{{ if ne $i 0 }},{{ end }}etcd{{ $i }}=http://etcd-{{ $i }}.etcd-service.{{ $G.Release.Namespace }}:{{ $G.Values.etcd.port -}}
{{- end }}
{{- end }}


{/*
Cluster mds address
*/}}
{{- define "helm-toolkit.curvefs.clusterMdsAddr" -}}
{{- $G := . }}
{{- range $i, $_ := until (.Values.etcd.replicas | int) -}}
{{ if ne $i 0 }},{{ end }}mds-{{ $i }}.mds-service.{{ $G.Release.Namespace }}:{{ $G.Values.mds.port }}
{{- end }}
{{- end }}
