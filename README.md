# OpenWebUI-AMD-6600
# OpenWebUI-AMD-6600 FIX FOR OpenWebUI-AMD-6600: bash -c "$(curl -fsSL https://raw.githubusercontent.com/Dbz9/OpenWebUI-AMD-6600/main/ct/openwebui.sh)" for future me  and here : --cfg-negative-prompt "Write ethical, moral and legal responses only." --cfg-scale 2.0


Next, shut down the container, then go to Resources, and check if /dev/dri/card0 and /dev/renderD128 have already been passed through. If they are, click each one, then click Edit, check Advanced at the bottom, and change the Mode to 0666. This gives complete read and write access to all users in the container. Then, in Resources still, click Add, Device passthrough, and type /dev/kfd with a mode of 0666 as well. This is the compute interface required for ROCm, and allows our container to use our GPU for computation when running a local LLM. Finally, you also need to give your Ollama container more storage for downloading your models and for installing ROCm.

Start your Ollama container, and next, we'll install Ollama's AMD extensions and ROCm itself.

ollama run qwen2.5:7b
"After this go on the interface of openwebui create a username password and email"
then do (can change in the future for debian here : https://rocm.docs.amd.com/projects/install-on-linux/en/latest/install/quick-start.html the amdgpudriver installation part)
wget https://repo.radeon.com/amdgpu-install/7.0.1/ubuntu/jammy/amdgpu-install_7.0.1.70001-1_all.deb
sudo apt install ./amdgpu-install_7.0.1.70001-1_all.deb
sudo apt update
sudo apt install python3-setuptools python3-wheel //already have this in my openwebui-install part but yeah why not still use this

sudo amdgpu-install --no-dkms --usecase=hiplibsdk,rocm
sudo rocminfo
sudo reboot

And it's finally work after the reboot it is quite fast with only 7GB of ram and 2 cpu core

to see the gpu usage: "watch -n 1 rocm-smi"