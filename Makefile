.PHONY: debug install uninstall status list

debug:
	@helm install --dry-run --debug curvefs-release ./curvefs -n curvefs

install:
	@helm upgrade --install curvefs-release ./curvefs -f topology.yaml -n curvefs --create-namespace

uninstall:
	@helm uninstall curvefs-release -n curvefs

status:
	@helm status curvefs-release -n curvefs

list:
	@helm list -n curvefs
