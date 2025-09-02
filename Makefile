.PHONY: make-deploy

install:
	forge install && npm i && forge build
deploy-mainnet-sourcify:
	forge script script/DeployBridge.s.sol \
	 --rpc-url eth_mainnet_sandbox \
	 --verifier sourcify \
	 --verify \
	 --verifier-url https://rpc.buildbear.io/verify/sourcify/server/eth-to-pol \
	 --broadcast \

deploy-pol-sourcify:
	forge script script/DeployBridge.s.sol \
	 --rpc-url pol_mainnet_sandbox \
	 --verifier sourcify \
	 --verify \
	 --verifier-url https://rpc.buildbear.io/verify/sourcify/server/pol-to-eth \
	 --broadcast \

interact-mainnet-bridge:
	forge script script/InteractBridge.s.sol \
	 --rpc-url eth_mainnet_sandbox \
	 --broadcast \

interact-pol-bridge:
	forge script script/InteractBridge.s.sol \
	 --rpc-url eth_mainnet_sandbox \
	 --broadcast \