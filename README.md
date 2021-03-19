# README

## Windows 上での Rancher 登録

WITHOUT_VERIFICATION=true をセットする。

```powershell
PowerShell -NoLogo -NonInteractive -Command "& {docker run -e WITHOUT_VERIFICATION=true -v c:\:c:\host rancher/rancher-agent:v2.5.3 bootstrap --server https://10.0.2.11 --token xgv7shbbwxnkswp4qtwthtd692gbcchk45xt885vbmxdcqfl9nnbs8 --ca-checksum 55488b9ecd990bf5a86620b68c615c0c74c8b9789346c833fee2644bf158f4b6 --worker | iex}"
```

## エラーが出たら

/etc/kubernetes を削除する
