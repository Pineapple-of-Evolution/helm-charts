{{- define "nuc-rabbitmq.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "nuc-rabbitmq.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "nuc-rabbitmq.labels" -}}
app.kubernetes.io/name: {{ include "nuc-rabbitmq.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ include "nuc-rabbitmq.chart" . }}
{{- end -}}

{{- define "nuc-rabbitmq.tplvalues.render" -}}
{{- if typeIs "string" .value -}}
{{- tpl .value .context -}}
{{- else -}}
{{- tpl (.value | toYaml) .context -}}
{{- end -}}
{{- end -}}

{{- define "nuc-rabbitmq.tplContext" -}}
{{- $tplContext := deepCopy . -}}
{{- if .Values.global -}}
{{- $_ := set $tplContext "Values" (mergeOverwrite (deepCopy .Values.global) .Values) -}}
{{- end -}}
{{- $tplContext | toYaml -}}
{{- end -}}

{{- define "nuc-rabbitmq.renderMap" -}}
{{- $value := .value | default dict -}}
{{- $context := .context -}}
{{- if $value -}}
{{- include "nuc-rabbitmq.tplvalues.render" (dict "value" $value "context" $context) | fromYaml | default dict | toYaml -}}
{{- else -}}
{{- dict | toYaml -}}
{{- end -}}
{{- end -}}

{{- define "nuc-rabbitmq.commonLabels" -}}
{{- $root := .root -}}
{{- $context := .context -}}
{{- $commonLabels := include "nuc-rabbitmq.renderMap" (dict "value" ($root.Values.commonLabels | default dict) "context" $context) | fromYaml | default dict -}}
{{- $genericLabels := include "nuc-rabbitmq.renderMap" (dict "value" ((get ($root.Values.generic | default dict) "labels") | default dict) "context" $context) | fromYaml | default dict -}}
{{- mustMergeOverwrite (dict) $commonLabels $genericLabels | toYaml -}}
{{- end -}}

{{- define "nuc-rabbitmq.commonAnnotations" -}}
{{- $root := .root -}}
{{- $context := .context -}}
{{- $commonAnnotations := include "nuc-rabbitmq.renderMap" (dict "value" ($root.Values.commonAnnotations | default dict) "context" $context) | fromYaml | default dict -}}
{{- $genericAnnotations := include "nuc-rabbitmq.renderMap" (dict "value" ((get ($root.Values.generic | default dict) "annotations") | default dict) "context" $context) | fromYaml | default dict -}}
{{- mustMergeOverwrite (dict) $commonAnnotations $genericAnnotations | toYaml -}}
{{- end -}}

{{- define "nuc-rabbitmq.resourceSpec" -}}
{{- $item := .item | default dict -}}
{{- $context := .context -}}
{{- if hasKey $item "spec" -}}
{{ include "nuc-rabbitmq.tplvalues.render" (dict "value" $item.spec "context" $context) }}
{{- end -}}
{{- end -}}

{{- define "nuc-rabbitmq.resolveApiVersion" -}}
{{- $root := .root -}}
{{- $key := .key -}}
{{- $legacyKey := .legacyKey -}}
{{- $topLevel := get ($root.Values.apiVersions | default dict) $key -}}
{{- $globalApiVersions := get ($root.Values.global | default dict) "apiVersions" | default dict -}}
{{- $globalValue := get $globalApiVersions $legacyKey -}}
{{- if and $topLevel (ne $topLevel .default) -}}
{{- $topLevel -}}
{{- else if $globalValue -}}
{{- $globalValue -}}
{{- else -}}
{{- default .default $topLevel -}}
{{- end -}}
{{- end -}}

{{- define "nuc-rabbitmq.renderResource" -}}
{{- $root := .root -}}
{{- $item := .item -}}
{{- $resourceName := .resourceName -}}
{{- $resourceKey := .resourceKey -}}
{{- $tplContext := include "nuc-rabbitmq.tplContext" $root | fromYaml -}}
{{- $shouldIgnore := eq (get ($item.annotations | default dict) "helm-docs.nuc.internal/ignore") "true" -}}
{{- if not $shouldIgnore -}}
{{- $defaultLabels := include "nuc-rabbitmq.labels" $root | fromYaml -}}
{{- $commonLabels := include "nuc-rabbitmq.commonLabels" (dict "root" $root "context" $tplContext) | fromYaml -}}
{{- $itemLabels := include "nuc-rabbitmq.renderMap" (dict "value" ($item.labels | default dict) "context" $tplContext) | fromYaml | default dict -}}
{{- $labels := mustMergeOverwrite (dict) $defaultLabels $commonLabels $itemLabels -}}
{{- $commonAnnotations := include "nuc-rabbitmq.commonAnnotations" (dict "root" $root "context" $tplContext) | fromYaml -}}
{{- $itemAnnotations := include "nuc-rabbitmq.renderMap" (dict "value" ($item.annotations | default dict) "context" $tplContext) | fromYaml | default dict -}}
{{- $annotations := mustMergeOverwrite (dict) $commonAnnotations $itemAnnotations -}}
{{- $nameValue := required (printf "%s key is required" $resourceKey) ($item.name | default $resourceName) -}}
apiVersion: {{ default .defaultApiVersion $item.apiVersion }}
kind: {{ .kind }}
metadata:
  name: {{ include "nuc-rabbitmq.tplvalues.render" (dict "value" $nameValue "context" $tplContext) }}
  {{- if .namespaced }}
  namespace: {{ default $root.Release.Namespace $item.namespace }}
  {{- end }}
  labels:
{{ toYaml $labels | nindent 4 }}
  {{- if $annotations }}
  annotations:
{{ toYaml $annotations | nindent 4 }}
  {{- end }}
{{- $spec := include "nuc-rabbitmq.resourceSpec" (dict "item" $item "context" $tplContext) -}}
{{- if $spec }}
spec:
{{ $spec | nindent 2 }}
{{- end }}
{{- with $item.status }}
status:
{{ include "nuc-rabbitmq.tplvalues.render" (dict "value" . "context" $tplContext) | nindent 2 }}
{{- end }}
{{- end -}}
{{- end -}}

{{- define "nuc-rabbitmq.renderResources" -}}
{{- $collection := .collection | default dict -}}
{{- $documents := list -}}
{{- range $resourceName := keys $collection | sortAlpha -}}
{{- $item := get $collection $resourceName -}}
{{- if and (ne $resourceName "__helm_docs_example__") (kindIs "map" $item) -}}
{{- $rendered := include "nuc-rabbitmq.renderResource" (dict
  "root" $.root
  "item" $item
  "resourceName" $resourceName
  "resourceKey" (printf "%s[%q]" $.resourceKey $resourceName)
  "kind" $.kind
  "defaultApiVersion" $.defaultApiVersion
  "namespaced" $.namespaced
) -}}
{{- if $rendered -}}
{{- $documents = append $documents $rendered -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- join "\n---\n" $documents -}}
{{- end -}}

{{/* Compatibility aliases for umbrella helpers. */}}
{{- define "helpers.tplvalues.render" -}}
{{- include "nuc-rabbitmq.tplvalues.render" . -}}
{{- end -}}

{{- define "helpers.app.fullname" -}}
{{- include "nuc-rabbitmq.name" .context -}}
{{- end -}}

{{- define "helpers.app.labels" -}}
{{- include "nuc-rabbitmq.labels" . -}}
{{- end -}}

{{- define "helpers.app.genericAnnotations" -}}
{{- $tplContext := include "nuc-rabbitmq.tplContext" . | fromYaml -}}
{{- include "nuc-rabbitmq.commonAnnotations" (dict "root" . "context" $tplContext) -}}
{{- end -}}
