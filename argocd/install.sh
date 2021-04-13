kubectl create ns argocd
kubectl label namespace argocd istio-injection=enabled 

-- 로그인 --
argocd login --grpc-web argocd.prod-itoo.co.kr:80 --name prod-ndp-eks-cluster-context

-- Git 연동 --
argocd repo add --name phh-fo --username argocd-at-217585811528 --password t4AWnd7MepZzwjiFqFsHj1UWo6UyWHAWbyUwcM4bQFI= https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/phh-fo
argocd repo add --name phh-bo --username argocd-at-217585811528 --password t4AWnd7MepZzwjiFqFsHj1UWo6UyWHAWbyUwcM4bQFI= https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/phh-bo

argocd repo add --name backoffice --username argocd-at-217585811528 --password t4AWnd7MepZzwjiFqFsHj1UWo6UyWHAWbyUwcM4bQFI= https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/backoffice
argocd repo add --name batch --username argocd-at-217585811528 --password t4AWnd7MepZzwjiFqFsHj1UWo6UyWHAWbyUwcM4bQFI= https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/batch
argocd repo add --name customsvc --username argocd-at-217585811528 --password t4AWnd7MepZzwjiFqFsHj1UWo6UyWHAWbyUwcM4bQFI= https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/customsvc
argocd repo add --name diquest --username argocd-at-217585811528 --password t4AWnd7MepZzwjiFqFsHj1UWo6UyWHAWbyUwcM4bQFI= https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/diquest
argocd repo add --name display --username argocd-at-217585811528 --password t4AWnd7MepZzwjiFqFsHj1UWo6UyWHAWbyUwcM4bQFI= https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/display
argocd repo add --name goods --username argocd-at-217585811528 --password t4AWnd7MepZzwjiFqFsHj1UWo6UyWHAWbyUwcM4bQFI= https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/goods
argocd repo add --name ifimall --username argocd-at-217585811528 --password t4AWnd7MepZzwjiFqFsHj1UWo6UyWHAWbyUwcM4bQFI= https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/ifimall
argocd repo add --name ifmng --username argocd-at-217585811528 --password t4AWnd7MepZzwjiFqFsHj1UWo6UyWHAWbyUwcM4bQFI= https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/ifmng
argocd repo add --name member --username argocd-at-217585811528 --password t4AWnd7MepZzwjiFqFsHj1UWo6UyWHAWbyUwcM4bQFI= https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/member
argocd repo add --name order --username argocd-at-217585811528 --password t4AWnd7MepZzwjiFqFsHj1UWo6UyWHAWbyUwcM4bQFI= https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/order
argocd repo add --name partner --username argocd-at-217585811528 --password t4AWnd7MepZzwjiFqFsHj1UWo6UyWHAWbyUwcM4bQFI= https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/partner
argocd repo add --name relay --username argocd-at-217585811528 --password t4AWnd7MepZzwjiFqFsHj1UWo6UyWHAWbyUwcM4bQFI= https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/relay
argocd repo add --name vcmo --username argocd-at-217585811528 --password t4AWnd7MepZzwjiFqFsHj1UWo6UyWHAWbyUwcM4bQFI= https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/vcmo
argocd repo add --name fcmo --username argocd-at-217585811528 --password t4AWnd7MepZzwjiFqFsHj1UWo6UyWHAWbyUwcM4bQFI= https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/fcmo

argocd repo add --name csi --username argocd-at-217585811528 --password t4AWnd7MepZzwjiFqFsHj1UWo6UyWHAWbyUwcM4bQFI= https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/csi
argocd repo add --name csioffice --username argocd-at-217585811528 --password t4AWnd7MepZzwjiFqFsHj1UWo6UyWHAWbyUwcM4bQFI= https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/csioffice

-- CREATE APP --
argocd app create phh-fo --repo https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/phh-fo --path phh-fo --revision master-gitops --revision-history-limit 5 --dest-server https://kubernetes.default.svc --dest-namespace phh-test-fo
argocd app create phh-bo --repo https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/phh-bo --path phh-bo --revision master-gitops --revision-history-limit 5 --dest-server https://kubernetes.default.svc --dest-namespace phh-test-bo

argocd app create backoffice --repo https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/backoffice --revision master-gitops --revision-history-limit 5 --path backoffice --dest-server https://kubernetes.default.svc --dest-namespace prod-backend-backoffice
argocd app create batch --repo https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/batch --revision master-gitops --revision-history-limit 5 --path batch --dest-server https://kubernetes.default.svc --dest-namespace prod-backend-batch
argocd app create customsvc --repo https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/customsvc --revision master-gitops --revision-history-limit 5 --path customsvc --dest-server https://kubernetes.default.svc --dest-namespace prod-backend-customsvc
argocd app create diquest --repo https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/diquest --revision master-gitops --revision-history-limit 5 --path diquest --dest-server https://kubernetes.default.svc --dest-namespace prod-backend-diquest
argocd app create display --repo https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/display --revision master-gitops --revision-history-limit 5 --path display --dest-server https://kubernetes.default.svc --dest-namespace prod-backend-display
argocd app create goods --repo https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/goods --revision master-gitops --revision-history-limit 5 --path goods --dest-server https://kubernetes.default.svc --dest-namespace prod-backend-goods
argocd app create ifmng --repo https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/ifmng --revision master-gitops --revision-history-limit 5 --path ifmng --dest-server https://kubernetes.default.svc --dest-namespace prod-frontend-ifmng
argocd app create member --repo https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/member --revision master-gitops --revision-history-limit 5 --path member --dest-server https://kubernetes.default.svc --dest-namespace prod-backend-member
argocd app create order --repo https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/order --revision master-gitops --revision-history-limit 5 --path order --dest-server https://kubernetes.default.svc --dest-namespace prod-backend-order
argocd app create partner --repo https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/partner --revision master-gitops --revision-history-limit 5 --path partner --dest-server https://kubernetes.default.svc --dest-namespace prod-backend-partner
argocd app create relay --repo https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/relay --revision master-gitops --revision-history-limit 5 --path relay --dest-server https://kubernetes.default.svc --dest-namespace prod-backend-relay
argocd app create vcmo --repo https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/vcmo --revision master-gitops --revision-history-limit 5 --path vcmo --dest-server https://kubernetes.default.svc --dest-namespace prod-frontend-vcmo
argocd app create fcmo --repo https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/fcmo --revision master-gitops --revision-history-limit 5 --path fcmo --dest-server https://kubernetes.default.svc --dest-namespace prod-frontend-fcmo

argocd app create csi --repo https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/csi --revision master-gitops --revision-history-limit 5 --path csi --dest-server https://kubernetes.default.svc --dest-namespace prod-frontend-csi
argocd app create csioffice --repo https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/csioffice --revision master-gitops --revision-history-limit 5 --path csioffice --dest-server https://kubernetes.default.svc --dest-namespace prod-backend-csioffice


------------------------------------------------------------------------------------------------------------------------------------------------------------------------

<helm2>
-- 설치 -- 
helm install --name argocd --namespace argocd argo/argo-cd --values ./values.yaml

-- 삭제시 --
helm del --purge argocd
kubectl delete customresourcedefinition/applications.argoproj.io -n argocd --force=true --grace-period=0 
kubectl delete customresourcedefinition/appprojects.argoproj.io -n argocd --force=true --grace-period=0

---upgrade--
helm upgrade --install argocd --values ./values.yaml argo/argo-cd

------------------------------------------------------------------------------------------------------------------------------------------------------------------------

<helm3>
-- 설치 --
helm repo add argo https://argoproj.github.io/argo-helm
helm install -f ./values.yaml -n argocd argocd argo/argo-cd
helm upgrade -f ./values.yaml -n argocd argocd argo/argo-cd

-- 삭제 --
helm uninstall argocd -n argocd
kubectl delete customresourcedefinition/applications.argoproj.io -n argocd --force=true --grace-period=0 
kubectl delete customresourcedefinition/appprojects.argoproj.io -n argocd --force=true --grace-period=0
