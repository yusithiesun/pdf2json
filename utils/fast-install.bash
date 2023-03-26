#!/bin/bash

## purple to echo
function purple(){
    echo -e "\033[35m$1\033[0m"
}


## green to echo
function green(){
    echo -e "\033[32m$1\033[0m"
}

## Error to warning with blink
function bred(){
    echo -e "\033[31m\033[01m\033[05m$1\033[0m"
}

## Error to warning with blink
function byellow(){
    echo -e "\033[33m\033[01m\033[05m$1\033[0m"
}


## Error
function red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}

## warning
function yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}

path='http://paddlepaddle.org/download?url='
release_version=`curl -s https://pypi.org/project/paddlepaddle/|grep -E "/project/paddlepaddle/"|grep "release"|awk -F '/' '{print $(NF-1)}'|head -1`
python_list=(
"27"
"35"
"36"
"37"
)


function use_cpu(){
   while true
    do
     read -p "鏄惁瀹夎CPU鐗堟湰鐨凱addlePaddle锛�(y/n)" cpu_option
     cpu_option=`echo $cpu_option | tr 'A-Z' 'a-z'`
     if [[ "$cpu_option" == "" || "$cpu_option" == "n" ]];then
        echo "閫€鍑哄畨瑁呬腑..."
        exit
     else
        GPU='cpu'
        echo "灏嗕负鎮ㄥ畨瑁匔PU鐗堟湰鐨凱addlePaddle"
        break
     fi
    done
}

function checkLinuxCUDNN(){
   echo
   read -n1 -p "璇锋寜鍥炶溅閿繘琛屼笅涓€姝�..."
   echo
   while true
   do
       version_file='/usr/local/cuda/include/cudnn.h'
       if [ -f "$version_file" ];then
          CUDNN=`cat $version_file | grep CUDNN_MAJOR |awk 'NR==1{print $NF}'`
       fi
       if [ "$CUDNN" == "" ];then
           version_file=`sudo find /usr -name "cudnn.h"|head -1`
           if [ "$version_file" != "" ];then
               CUDNN=`cat ${version_file} | grep CUDNN_MAJOR -A 2|awk 'NR==1{print $NF}'`
           else
               echo "妫€娴嬬粨鏋滐細鏈湪甯歌璺緞涓嬫壘鍒癱uda/include/cudnn.h鏂囦欢"
               while true
               do
                  read -p "璇锋牳瀹瀋udnn.h浣嶇疆锛屽苟鍦ㄦ杈撳叆璺緞锛堣娉ㄦ剰锛岃矾寰勯渶瑕佽緭鍏ュ埌鈥渃udnn.h鈥濊繖涓€绾э級:" cudnn_version
                  echo
                  if [ "$cudnn_version" == "" ] || [ ! -f "$cudnn_version" ];then
                        read -p "浠嶆湭鎵惧埌cuDNN锛岃緭鍏灏嗗畨瑁匔PU鐗堟湰鐨凱addlePaddle锛岃緭鍏鍙噸鏂板綍鍏uDNN璺緞锛岃杈撳叆锛坹/n锛�" cpu_option
                        echo
                        cpu_option=`echo $cpu_option | tr 'A-Z' 'a-z'`
                        if [ "$cpu_option" == "y" -o "$cpu_option" == "" ];then
                            GPU='cpu'
                            break
                        else
                            echo "璇烽噸鏂拌緭鍏�"
                            echo
                        fi
                  else
                     CUDNN=`cat $cudnn_version | grep CUDNN_MAJOR |awk 'NR==1{print $NF}'`
                     echo "妫€娴嬬粨鏋滐細鎵惧埌cudnn.h"
                     break
                  fi
                 done
             if [ "$GPU" == "cpu" ];then
                break
             fi
           fi
       fi
       if [ "$CUDA" == "9" -a "$CUDNN" != "7" ];then
           echo
           echo "鐩墠CUDA9涓嬩粎鏀寔cuDNN7锛屾殏涓嶆敮鎸佹偍鏈哄櫒涓婄殑CUDNN${CUDNN}銆傛偍鍙互璁块棶NVIDIA瀹樼綉涓嬭浇閫傚悎鐗堟湰鐨凜UDNN锛岃ctrl+c閫€鍑哄畨瑁呰繘绋嬨€傛寜鍥炶溅閿皢涓烘偍瀹夎CPU鐗堟湰鐨凱addlePaddle"
           echo
          use_cpu()
          if [ "$GPU"=="cpu" ];then
             break
          fi
       fi

       if [ "$CUDNN" == 5 ] || [ "$CUDNN" == 7 ];then
          echo
          echo "鎮ㄧ殑CUDNN鐗堟湰鏄�: CUDNN$CUDNN"
          break
       else
          echo
          read -n1 -p "鐩墠鏀寔鐨凜UDNN鐗堟湰涓�5鍜�7,鏆備笉鏀寔鎮ㄦ満鍣ㄤ笂鐨凜UDNN${CUDNN}锛屽皢涓烘偍瀹夎CPU鐗堟湰鐨凱addlePaddle,璇锋寜鍥炶溅閿紑濮嬪畨瑁�"
          echo
          use_cpu
          if [ "$GPU"=="cpu" ];then
             break
          fi
       fi
   done
}

function checkLinuxCUDA(){
   while true
   do
       CUDA=`echo ${CUDA_VERSION}|awk -F "[ .]" '{print $1}'`
       if [ "$CUDA" == "" ];then
         if [ -f "/usr/local/cuda/version.txt" ];then
           CUDA=`cat /usr/local/cuda/version.txt | grep 'CUDA Version'|awk -F '[ .]' '{print $3}'`
           tmp_cuda=$CUDA
         fi
         if [ -f "/usr/local/cuda8/version.txt" ];then
           CUDA=`cat /usr/local/cuda8/version.txt | grep 'CUDA Version'|awk -F '[ .]' '{print $3}'`
           tmp_cuda8=$CUDA
         fi
         if [ -f "/usr/local/cuda9/version.txt" ];then
           CUDA=`cat /usr/local/cuda9/version.txt | grep 'CUDA Version'|awk -F '[ .]' '{print $3}'`
           tmp_cuda9=$CUDA
         fi
         if [ -f "/usr/local/cuda10/version.txt" ];then
           CUDA=`cat /usr/local/cuda10/version.txt | grep 'CUDA Version'|awk -F '[ .]' '{print $3}'`
           tmp_cuda10=$CUDA
         fi
       fi

       if [ "$tmp_cuda" != "" ];then
         echo "妫€娴嬬粨鏋滐細鎵惧埌CUDA $tmp_cuda"
       fi
       if [ "$tmp_cudai8" != "" ];then
         echo "妫€娴嬬粨鏋滐細鎵惧埌CUDA $tmp_cuda8"
       fi
       if [ "$tmp_cuda9" != "" ];then
         echo "妫€娴嬬粨鏋滐細鎵惧埌CUDA $tmp_cuda9"
       fi
       if [ "$tmp_cuda10" != "" ];then
         echo "妫€娴嬬粨鏋滐細鎵惧埌CUDA $tmp_cuda10"
       fi

       if [ "$CUDA" == "" ];then
            echo "妫€娴嬬粨鏋滐細娌℃湁鍦ㄥ父瑙勮矾寰勪笅鎵惧埌cuda/version.txt鏂囦欢"
            while true
            do
                read -p "璇疯緭鍏uda/version.txt鐨勮矾寰�:" cuda_version
                if [ "$cuda_version" == "" || ! -f "$cuda_version" ];then
                    read -p "浠嶆湭鎵惧埌CUDA锛岃緭鍏灏嗗畨瑁匔PU鐗堟湰鐨凱addlePaddle锛岃緭鍏鍙噸鏂板綍鍏UDA璺緞锛岃杈撳叆锛坹/n锛�" cpu_option
                    cpu_option=`echo $cpu_option | tr 'A-Z' 'a-z'`
                    if [ "$cpu_option" == "y" || "$cpu_option" == "" ];then
                        GPU='cpu'
                        break
                    else
                        echo "閲嶆柊杈撳叆..."
                    fi
                else
                    CUDA=`cat $cuda_version | grep 'CUDA Version'|awk -F '[ .]' '{print $3}'`
                    if [ "$CUDA" == "" ];then
                        echo "鏈兘鍦╲ersion.txt涓壘鍒癈UDA鐩稿叧淇℃伅"
                    else
                        break
                    fi
                fi
            done
            if [ "$GPU" == "cpu" ];then
                break
            fi
       fi

       if [ "$CUDA" == "8" ] || [ "$CUDA" == "9" ] || [ "$CUDA" == "10" ];then
          echo "鎮ㄧ殑CUDA鐗堟湰鏄�${CUDA}"
          break
       else
          echo "鐩墠鏀寔CUDA8/9/10锛屾殏涓嶆敮鎸佹偍鐨凜UDA${CUDA}锛屽皢涓烘偍瀹夎CPU鐗堟湰鐨凱addlePaddle"
          echo
          use_cpu
       fi

       if [ "$GPU" == "cpu" ];then
          break
       fi
   done
}

function checkLinuxMathLibrary(){
  while true
    do
      if [ "$GPU" == "gpu" ];then
        math='mkl'
        echo "妫€娴嬪埌鎮ㄧ殑鏈哄櫒涓婇厤澶嘒PU锛屾帹鑽愭偍浣跨敤mkl鏁板搴�"
        break
      else
        read -p "璇疯緭鍏ユ偍甯屾湜浣跨敤鐨勬暟瀛﹀簱锛�
            1锛歰penblas 涓€涓珮鎬ц兘澶氭牳 BLAS 搴�
            2锛歮kl锛堟帹鑽愶級 鑻辩壒灏旀暟瀛︽牳蹇冨嚱鏁板簱
            => 璇疯緭鍏ユ暟瀛�1鎴�2銆傚杈撳叆鍏朵粬瀛楃鎴栫洿鎺ュ洖杞︼紝灏嗕細榛樿閫夋嫨銆� 2. mkl 銆� 銆傝鍦ㄨ繖閲岃緭鍏ュ苟鍥炶溅锛�" math
          if [ "$math" == "" ];then
            math="mkl"
            echo "鎮ㄩ€夋嫨浜嗘暟瀛椼€�2銆�"
            break
          fi
          if [ "$math" == "1" ];then
            math=openblas
            echo "鎮ㄩ€夋嫨浜嗘暟瀛椼€�1銆�"
            break
          elif [ "$math" == "2" ];then
            math=mkl
            echo "鎮ㄩ€夋嫨浜嗘暟瀛椼€�2銆�"
            break
          fi
          echo "杈撳叆閿欒锛岃鍐嶆杈撳叆"
      fi
    done
}

function checkLinuxPaddleVersion(){
  read -n1 -p "璇锋寜鍥炶溅閿户缁�..."
  while true
    do
      read -p "
               1. 寮€鍙戠増锛氬搴擥ithub涓奷evelop鍒嗘敮锛屽鎮ㄩ渶瑕佸紑鍙戙€佹垨甯屾湜浣跨敤PaddlePaddle鏈€鏂板姛鑳斤紝璇烽€夌敤姝ょ増鏈�
               2. 绋冲畾鐗堬紙鎺ㄨ崘锛夛細濡傛偍鏃犵壒娈婂紑鍙戦渶姹傦紝寤鸿浣跨敤姝ょ増鏈紝鐩墠鏈€鏂扮殑鐗堟湰鍙蜂负 ${release_version}
                => 璇疯緭鍏ユ暟瀛�1鎴�2銆傚杈撳叆鍏朵粬瀛楃鎴栫洿鎺ュ洖杞︼紝灏嗕細榛樿閫夋嫨銆� 2. 绋冲畾鐗� 銆� 銆傝鍦ㄨ繖閲岃緭鍏ュ苟鍥炶溅锛�" paddle_version
        if [ "$paddle_version" == "" ];then
          paddle_version="2"
          echo "鎮ㄩ€夋嫨浜嗘暟瀛椼€�2銆戯紝涓烘偍瀹夎release-${release_version}"
          break
        fi
        if [ "$paddle_version" == "1" ];then
          echo "鎮ㄩ€夋嫨浜嗘暟瀛椼€�1銆戯紝灏嗕负鎮ㄥ畨瑁呭紑鍙戠増"
          break
        elif [ "$paddle_version" == "2" ];then
          echo "鎮ㄩ€夋嫨浜嗘暟瀛椼€�2銆戯紝涓烘偍瀹夎release-${release_version}"
          break
        fi
        echo "杈撳叆閿欒锛岃鍐嶆杈撳叆"
    done
}

function checkPythonVirtualenv(){
  while true
    do
      read -p "
                鏄惁浣跨敤python  virtualenv铏氱幆澧冨畨瑁�(y/n)": check_virtualenv
    case $check_virtualenv in
      y)
        echo "涓烘偍浣跨敤python铏氱幆澧冨畨瑁�"
        ;;
      n)
        break
        ;;
      *)
        continue
        ;;
    esac

    virtualenv_path=`which virtualenv 2>&1`
    if [ "$virtualenv_path" == "" ];then
      $python_path -m pip install virtualenv
      if [ "$?" != '0' ];then
        echo "瀹夎铏氭嫙鐜澶辫触,璇锋鏌ユ湰鍦扮幆澧�"
      fi
    fi

    while true
      do
        read -p "璇疯緭鍏ヨ櫄鎷熺幆澧冨悕瀛楋細" virtualenv_name
        if [ "$virtualenv_name" == "" ];then
          echo "涓嶈兘涓虹┖"
          continue
        fi
        break
    done

    virtualenv -p $python_path ${virtualenv_name}
    if [ "$?" != 0 ];then
      echo "鍒涘缓铏氱幆澧冨け璐�,璇锋鏌ョ幆澧�"
      exit 2
    fi
    cd ${virtualenv_name}
    source ./bin/activate

    if [ "$?" == 0 ];then
      use_virtualenv=
      python_path=`which python`
      break
    else
      echo "鍒涘缓铏氱幆澧冨け璐�,璇锋鏌ョ幆澧�"
      exit 2
    fi
  done
}

function checkLinuxPython(){
  python_path=`which python 2>/dev/null`
  while true
    do
  if [ "$python_path" == '' ];then
    while true
      do
        read -p "娌℃湁鎵惧埌榛樿鐨刾ython鐗堟湰,璇疯緭鍏ヨ瀹夎鐨刾ython璺緞:"  python_path
        python_path=`$python_path -V 2>&1` #add 2>&1
        if [ "$python_path" != "" ];then
          break
        else
          echo "杈撳叆璺緞鏈夎,鏈壘鍒皃yrhon"
        fi
    done
  fi

  python_version=`$python_path -V 2>&1|awk -F '[ .]' '{print $2$3}'`
  pip_version=`$python_path -m pip -V|awk -F '[ .]' '{print $2}'`
  while true
    do
      read -p "
                鎵惧埌python鐗堟湰$python_version,浣跨敤璇疯緭鍏,閫夋嫨鍏朵粬鐗堟湰璇疯緭n(y/n):"  check_python
      case $check_python in
        n)
          read -p "璇锋寚瀹氭偍鐨刾ython璺緞:" new_python_path
          python_V=`$new_python_path -V 2>&1` # 2>/dev/null --> 2>&1
          if [ "$python_V" != "" ];then
            python_path=$new_python_path
            python_version=`$python_path -V 2>&1|awk -F '[ .]' 'NR==1{print $2$3}'`
            echo $python_path
            pip_version=`$python_path -m pip -V|awk -F '[ .]' 'NR==1{print $2}'`
            echo "鎮ㄧ殑python鐗堟湰涓�${python_version}"
            break
          else
            echo 杈撳叆鏈夎,鏈壘鍒皃ython璺緞
          fi
          ;;
        y)
          break
          ;;
        *)
          echo "杈撳叆鏈夎锛岃閲嶆柊杈撳叆."
          continue
          ;;
      esac
  done

  if [ "$pip_version" -lt 10 ];then
    echo "鎮ㄧ殑pip鐗堟湰灏忎簬9.0.1  璇峰崌绾ip (pip install --upgrade pip)"
    exit 0
  fi


  if [ "$python_version" == "27" ];then
     python_version_all=`$python_path -V 2>&1|awk -F '[ .]' '{print $4}'`
     if [[ $python_version_all -le 15 ]];then
        echo "Python2鐗堟湰灏忎簬2.7.15,璇锋洿鏂癙ython2鐗堟湰鎴栦娇鐢≒ython3"
        exit 0
      fi
     uncode=`$python_path -c "import pip._internal;print(pip._internal.pep425tags.get_supported())"|grep "cp27mu"`
     if [[ "$uncode" == "" ]];then
        uncode=
     else
        uncode=u
     fi
  fi

  version_list=`echo "${python_list[@]}" | grep "$python_version" `
  if [ "$version_list" == "" ];then
    echo "鎵句笉鍒板彲鐢ㄧ殑 pip, 鎴戜滑鍙敮鎸丳ython27/35/36/37鍙婂叾瀵瑰簲鐨刾ip, 璇烽噸鏂拌緭鍏ワ紝 鎴栦娇鐢╟trl + c閫€鍑� "
  else
    break
  fi
  done
}


function PipLinuxInstall(){
  wheel_cpu_release="http://paddle-wheel.bj.bcebos.com/${release_version}-${GPU}-${math}/paddlepaddle-${release_version}-cp${python_version}-cp${python_version}m${uncode}-linux_x86_64.whl"
  wheel_gpu_release="http://paddle-wheel.bj.bcebos.com/${release_version}-gpu-cuda${CUDA}-cudnn${CUDNN}-${math}/paddlepaddle_gpu-${release_version}.post${CUDA}${CUDNN}-cp${python_version}-cp${python_version}m${uncode}-linux_x86_64.whl"
  wheel_cpu_develop="http://paddle-wheel.bj.bcebos.com/0.0.0-cpu-${math}/paddlepaddle-0.0.0-cp${python_version}-cp${python_version}m${uncode}-linux_x86_64.whl"
  wheel_gpu_develop="http://paddle-wheel.bj.bcebos.com/0.0.0-gpu-cuda${CUDA}-cudnn${CUDNN}-${math}/paddlepaddle_gpu-0.0.0-cp${python_version}-cp${python_version}m${uncode}-linux_x86_64.whl"


  if [[ "$paddle_version" == "2" ]];then
    if [[ "$GPU" == "gpu" ]];then
          rm -rf `echo $wheel_cpu_release|awk -F '/' '{print $NF}'`
          echo $wheel_gpu_release
          wget -q $wheel_gpu_release
          if [ "$?" == "0" ];then
            $python_path -m pip install -U ${use_virtualenv} -i https://mirrors.aliyun.com/pypi/simple --trusted-host=mirrors.aliyun.com $wheel_gpu_release
            if [ "$?" == 0 ];then
              echo 瀹夎鎴愬姛
              exit 0
            else
              echo 瀹夎澶辫触
              exit 1
            fi
          else
            echo paddlepaddle whl鍖呬笅杞藉け璐�
            echo "wget err: $wheel_gpu_release"
            exit 1
          fi
    else
        echo $wheel_cpu_release
        rm -rf `echo $wheel_cpu_release|awk -F '/' '{print $NF}'`
        wget -q $wheel_cpu_release
        if [ "$?" == "0" ];then
          $python_path -m pip install -U ${use_virtualenv} -i https://mirrors.aliyun.com/pypi/simple --trusted-host=mirrors.aliyun.com $wheel_cpu_release
          if [ "$?" == 0 ];then
              echo 瀹夎鎴愬姛
              exit 0
            else
              echo 瀹夎澶辫触
              exit 1
            fi
        else
          echo paddlepaddle whl鍖呬笅杞藉け璐�
          echo "wget err: $wheel_cpu_release"
          exit 1
        fi
    fi
  fi
  if [[ "$GPU" == "gpu" ]];then
        echo $wheel_gpu_develop
        rm -rf `echo $wheel_gpu_develop|awk -F '/' '{print $NF}'`
        wget -q $wheel_gpu_develop
        if [ "$?" == "0" ];then
          echo $python_path,111
          $python_path -m pip install -U ${use_virtualenv} -i https://mirrors.aliyun.com/pypi/simple --trusted-host=mirrors.aliyun.com $wheel_gpu_develop
          if [ "$?" == 0 ];then
              echo 瀹夎鎴愬姛
              exit 0
            else
              echo 瀹夎澶辫触
              exit 1
            fi
        else
          echo paddlepaddle whl鍖呬笅杞藉け璐�
          echo "wget err: $wheel_gpu_develop" 
          exit 1
        fi
  else
        echo $wheel_cpu_develop
        rm -rf `echo $wheel_cpu_develop|awk -F '/' '{print $NF}'`
        wget -q $wheel_cpu_develop
        if [ "$?" == "0" ];then
          $python_path -m pip install -U ${use_virtualenv} -i https://mirrors.aliyun.com/pypi/simple --trusted-host=mirrors.aliyun.com $wheel_cpu_develop
          if [ "$?" == 0 ];then
              echo 瀹夎鎴愬姛
              exit 0
            else
              echo 瀹夎澶辫触
              exit 1
            fi
        else
          echo paddlepaddle whl鍖呬笅杞藉け璐�
          echo "wget err: $wheel_cpu_develop"
          exit 1
        fi
    fi
}


function checkLinuxGPU(){
  read -n1 -p "鍗冲皢妫€娴嬫偍鐨勬満鍣ㄦ槸鍚﹀惈GPU锛岃鎸夊洖杞﹂敭缁х画..."
  echo
  which nvidia-smi >/dev/null 2>&1
  if [ "$?" != "0" ];then
    GPU='cpu'
    echo "鏈湪鏈哄櫒涓婃壘鍒癎PU锛屾垨PaddlePaddle鏆備笉鏀寔姝ゅ瀷鍙风殑GPU"
  else
    GPU='gpu'
    echo "宸插湪鎮ㄧ殑鏈哄櫒涓婃壘鍒癎PU锛屽嵆灏嗙‘璁UDA鍜孋UDNN鐗堟湰..."
    echo
  fi
  if [ "$GPU" == 'gpu' ];then
    checkLinuxCUDA
    checkLinuxCUDNN
  fi
}

function linux(){
gpu_list=(
"GeForce 410M"
"GeForce 610M"
"GeForce 705M"
"GeForce 710M"
"GeForce 800M"
"GeForce 820M"
"GeForce 830M"
"GeForce 840M"
"GeForce 910M"
"GeForce 920M"
"GeForce 930M"
"GeForce 940M"
"GeForce GT 415M"
"GeForce GT 420M"
"GeForce GT 430"
"GeForce GT 435M"
"GeForce GT 440"
"GeForce GT 445M"
"GeForce GT 520"
"GeForce GT 520M"
"GeForce GT 520MX"
"GeForce GT 525M"
"GeForce GT 540M"
"GeForce GT 550M"
"GeForce GT 555M"
"GeForce GT 610"
"GeForce GT 620"
"GeForce GT 620M"
"GeForce GT 625M"
"GeForce GT 630"
"GeForce GT 630M"
"GeForce GT 635M"
"GeForce GT 640"
"GeForce GT 640 (GDDR5)"
"GeForce GT 640M"
"GeForce GT 640M LE"
"GeForce GT 645M"
"GeForce GT 650M"
"GeForce GT 705"
"GeForce GT 720"
"GeForce GT 720M"
"GeForce GT 730"
"GeForce GT 730M"
"GeForce GT 735M"
"GeForce GT 740"
"GeForce GT 740M"
"GeForce GT 745M"
"GeForce GT 750M"
"GeForce GTS 450"
"GeForce GTX 1050"
"GeForce GTX 1060"
"GeForce GTX 1070"
"GeForce GTX 1080"
"GeForce GTX 1080 Ti"
"GeForce GTX 460"
"GeForce GTX 460M"
"GeForce GTX 465"
"GeForce GTX 470"
"GeForce GTX 470M"
"GeForce GTX 480"
"GeForce GTX 480M"
"GeForce GTX 485M"
"GeForce GTX 550 Ti"
"GeForce GTX 560M"
"GeForce GTX 560 Ti"
"GeForce GTX 570"
"GeForce GTX 570M"
"GeForce GTX 580"
"GeForce GTX 580M"
"GeForce GTX 590"
"GeForce GTX 650"
"GeForce GTX 650 Ti"
"GeForce GTX 650 Ti BOOST"
"GeForce GTX 660"
"GeForce GTX 660M"
"GeForce GTX 660 Ti"
"GeForce GTX 670"
"GeForce GTX 670M"
"GeForce GTX 670MX"
"GeForce GTX 675M"
"GeForce GTX 675MX"
"GeForce GTX 680"
"GeForce GTX 680M"
"GeForce GTX 680MX"
"GeForce GTX 690"
"GeForce GTX 750"
"GeForce GTX 750 Ti"
"GeForce GTX 760"
"GeForce GTX 760M"
"GeForce GTX 765M"
"GeForce GTX 770"
"GeForce GTX 770M"
"GeForce GTX 780"
"GeForce GTX 780M"
"GeForce GTX 780 Ti"
"GeForce GTX 850M"
"GeForce GTX 860M"
"GeForce GTX 870M"
"GeForce GTX 880M"
"GeForce GTX 950"
"GeForce GTX 950M"
"GeForce GTX 960"
"GeForce GTX 960M"
"GeForce GTX 965M"
"GeForce GTX 970"
"GeForce GTX 970M"
"GeForce GTX 980"
"GeForce GTX 980M"
"GeForce GTX 980 Ti"
"GeForce GTX TITAN"
"GeForce GTX TITAN Black"
"GeForce GTX TITAN X"
"GeForce GTX TITAN Z"
"Jetson TK1"
"Jetson TX1"
"Jetson TX2"
"Mobile Products"
"NVIDIA NVS 310"
"NVIDIA NVS 315"
"NVIDIA NVS 510"
"NVIDIA NVS 810"
"NVIDIA TITAN V"
"NVIDIA TITAN X"
"NVIDIA TITAN Xp"
"NVS 4200M"
"NVS 5200M"
"NVS 5400M"
"Quadro 410"
"Quadro GP100"
"Quadro K1100M"
"Quadro K1200"
"Quadro K2000"
"Quadro K2000D"
"Quadro K2100M"
"Quadro K2200"
"Quadro K2200M"
"Quadro K3100M"
"Quadro K4000"
"Quadro K4100M"
"Quadro K420"
"Quadro K4200"
"Quadro K4200M"
"Quadro K5000"
"Quadro K500M"
"Quadro K5100M"
"Quadro K510M"
"Quadro K5200"
"Quadro K5200M"
"Quadro K600"
"Quadro K6000"
"Quadro K6000M"
"Quadro K610M"
"Quadro K620"
"Quadro K620M"
"Quadro M1000M"
"Quadro M1200"
"Quadro M2000"
"Quadro M2000M"
"Quadro M2200"
"Quadro M3000M"
"Quadro M4000"
"Quadro M4000M"
"Quadro M5000"
"Quadro M5000M"
"Quadro M500M"
"Quadro M520"
"Quadro M5500M"
"Quadro M6000"
"Quadro M6000 24GB"
"Quadro M600M"
"Quadro M620"
"Quadro Mobile Products"
"Quadro P1000"
"Quadro P2000"
"Quadro P3000"
"Quadro P400"
"Quadro P4000"
"Quadro P5000"
"Quadro P600"
"Quadro P6000"
"Quadro Plex 7000"
"Tegra K1"
"Tegra X1"
"Tesla C2050/C2070"
"Tesla C2075"
"Tesla Data Center Products"
"Tesla K10"
"Tesla K20"
"Tesla K40"
"Tesla K80"
"Tesla M40"
"Tesla M60"
"Tesla P100"
"Tesla P4"
"Tesla P40"
"Tesla V100")

  echo "Step 2. 妫€娴婫PU鍨嬪彿鍜孋UDA/cuDNN鐗堟湰"
  echo
  checkLinuxGPU
  echo
  echo "Step 3. 妫€娴嬫暟瀛﹀簱"
  echo
  checkLinuxMathLibrary
  echo
  echo "Step 4. 閫夋嫨瑕佸畨瑁呯殑PaddlePaddle鐗堟湰"
  echo
  checkLinuxPaddleVersion
  echo
  echo "Step 5. 妫€娴媝ip鐗堟湰"
  echo
  checkLinuxPython
  echo
  echo "Step 6.鏄惁浣跨敤Python鐨勮櫄鎷熺幆澧�"
  use_virtualenv="--user"
  checkPythonVirtualenv
  echo "*********************2. 寮€濮嬪畨瑁�*****************************"
  PipLinuxInstall
  if [ "$check_virtualenv" == 'y' ];then
    echo "铏氱幆澧冨垱寤烘垚鍔燂紝璇穋d 杩涘叆${virtualenv_name}, 鎵ц source bin/activate銆€杩涘叆铏氱幆澧冦€傞€€鍑鸿櫄鐜鎵ц deactivate鍛戒护銆�
  鏇村铏氱幆澧冧娇鐢ㄦ柟娉曡鍙傝€僾irtualenv瀹樼綉:https://virtualenv.pypa.io/en/latest/"
  fi
}

function clearMacPythonEnv(){
   python_version=""
   python_brief_version=""
   python_root=""
}

function checkMacPython2(){
    while true
       do
          python_min="2.7.15"
          python_version=`$python_root --version 2>&1 1>&1`
          if [[ $? == "0" ]];then
               if [ "$python_version" == "" ] || ( [ "$python_root" == "/usr/bin/python" ] && ( [ "$python_version" \< "$python_min" ] || ( [ "$python_version" \> "$python_min" ] && [ ${#python_version} -lt ${#python_min} ] ) ) );then
                    clearMacPythonEnv
               elif [[ "$python_version" < "2.7.15" ]];then
                    echo -e "          => 鍦ㄦ偍鐨勭幆澧冧腑鎵惧埌 \033[32m[ $python_version ]\033[0m,姝ょ増鏈皬浜�2.7.15涓嶅缓璁娇鐢�,璇烽€夋嫨鍏朵粬鐗堟湰."
                    exit
               else
                    check_python=`echo $python_version | grep "Python 2"`
                    if [[ -n "$check_python" ]];then
                       while true
                         do
                           echo -e "          => 鍦ㄦ偍鐨勭幆澧冧腑鎵惧埌 \033[32m[ $python_version ]\033[0m, 纭浣跨敤姝ょ増鏈杈撳叆y锛涘鎮ㄥ笇鏈涜嚜瀹氫箟Python璺緞璇疯緭鍏銆傝鍦ㄨ繖閲岃緭鍏ワ紙y/n锛夊苟鍥炶溅: "
                           read -p "" use_python
                           echo
                           use_python=`echo $use_python | tr 'A-Z' 'a-z'`
                           if [[ "$use_python" == "y" ]]||[[ "$use_python" == "" ]];then
                                use_python="y"
                                break
                           elif [[ "$use_python" == "n" ]];then
                                clearMacPythonEnv
                                break
                           else
                               red "            杈撳叆閿欒锛岃閲嶆柊杈撳叆(y/n)"
                           fi
                       done
                       if [[ "$use_python" == "y" ]];then
                         return 0
                       fi
                    else
                       red "          鎮ㄨ緭鍏ython鐨勪笉鏄疨ython2"
                       clearMacPythonEnv
                    fi
               fi
          else
               clearMacPythonEnv
               red "          => 鏈兘鍦ㄥ父瑙勮矾寰勪笅鎵惧埌鍙敤鐨凱ython2锛岃浣跨敤ctrl+c鍛戒护閫€鍑哄畨瑁呯▼搴忥紝骞朵娇鐢╞rew鎴杙ypi.org涓嬭浇瀹夎Python2锛堟敞鎰廝ython鐗堟湰涓嶈兘浣庝簬2.7.15锛�"
               read -p "          濡傚笇鏈涜嚜瀹氫箟Python璺緞锛岃杈撳叆璺緞
          濡傛灉甯屾湜閲嶆柊閫夋嫨Python鐗堟湰锛岃鍥炶溅锛�" python_root
               echo
               if [[ "$python_root" == "" ]];then
                     python_V=""
                     clearMacPythonEnv
                     return 1
               fi
          fi
       done
}

function checkMacPython3(){
    while true
       do
          python_min="2.7.15"
          python_version=`$python_root --version 2>&1 1>&1`
          if [[ $? == "0" ]];then
               if [ "$python_version" == "" ] || ( [ "$python_root" == "/usr/bin/python" ] && ( [ "$python_version" \< "$python_min" ] || ( [ "$python_version" \> "$python_min" ] && [ ${#python_version} -lt ${#python_min} ] ) ) );then
                    clearMacPythonEnv
               else
                    check_python=`echo $python_version | grep "Python 3"`
                    if [[ -n "$check_python" ]];then
                       while true
                         do
                           echo -e "          => 鍦ㄦ偍鐨勭幆澧冧腑鎵惧埌 \033[32m[ $python_version ]\033[0m, 纭浣跨敤姝ょ増鏈杈撳叆y锛涘鎮ㄥ笇鏈涜嚜瀹氫箟Python璺緞璇疯緭鍏銆傝鍦ㄨ繖閲岃緭鍏ワ紙y/n锛夊苟鍥炶溅: "
                           read -p "" use_python
                           echo
                           use_python=`echo $use_python | tr 'A-Z' 'a-z'`
                           if [[ "$use_python" == "y" ]]||[[ "$use_python" == "" ]];then
                                use_python="y"
                                break
                           elif [[ "$use_python" == "n" ]];then
                                clearMacPythonEnv
                                break
                           else
                               red "            杈撳叆閿欒锛岃閲嶆柊杈撳叆(y/n)"
                           fi
                       done
                       if [[ "$use_python" == "y" ]];then
                         return 0
                       fi
                    else
                       red "          鎮ㄨ緭鍏ython鐨勪笉鏄疨ython3"
                       clearMacPythonEnv
                    fi
               fi
          else
               clearMacPythonEnv
               red "          => 鏈兘鍦ㄥ父瑙勮矾寰勪笅鎵惧埌鍙敤鐨凱ython3锛岃浣跨敤ctrl+c鍛戒护閫€鍑哄畨瑁呯▼搴忥紝骞朵娇鐢╞rew鎴杙ypi.org涓嬭浇瀹夎Python3锛堟敞鎰廝ython鐗堟湰涓嶈兘浣庝簬3.5.x)"
               read -p "          濡傚笇鏈涜嚜瀹氫箟Python璺緞锛岃杈撳叆璺緞
          濡傛灉甯屾湜閲嶆柊閫夋嫨Python鐗堟湰锛岃鍥炶溅锛�" python_root
               echo
               if [[ "$python_root" == "" ]];then
                     python_V=""
                     clearMacPythonEnv
                     return 1
               fi
          fi
       done
}

function checkMacPaddleVersion(){
    echo
    yellow "          鐩墠PaddlePaddle鍦∕acOS鐜涓嬪彧鎻愪緵绋冲畾鐗堬紝鏈€鏂扮殑鐗堟湰鍙蜂负 ${release_version}"
    echo
    paddle_version="2"
    echo
    yellow "          鎴戜滑灏嗕細涓烘偍瀹夎PaddlePaddle绋冲畾鐗堬紝璇锋寜鍥炶溅閿户缁�... "
    read -n1 -p ""
    echo
}
function initCheckMacPython2(){
   echo
   yellow "          鎮ㄩ€夋嫨浜哖ython "$python_V"锛屾鍦ㄥ鎵剧鍚堣姹傜殑Python 2鐗堟湰"
   echo
   python_root=`which python2.7`
   if [[ "$python_root" == "" ]];then
        python_root=`which python`
   fi
   checkMacPython2
   if [[ "$?" == "1" ]];then
        return 1
   else
        return 0
   fi
}

function initCheckMacPython3(){
   echo
   yellow "          鎮ㄩ€夋嫨浜哖ython "$python_V"锛屾鍦ㄥ鎵剧鍚堟偍瑕佹眰鐨凱ython 3鐗堟湰"
   echo
   python_root=`which python3`
   checkMacPython3
   if [[ "$?" == "1" ]];then
        return 1
   else
        return 0
   fi
}

function checkMacPip(){
   if [[ "$python_V" == "2" ]]||[[ "$python_V" == "3" ]];then

       python_brief_version=`$python_root -m pip -V |awk -F "[ |)]" '{print $6}'|sed 's#\.##g'`
       if [[ ${python_brief_version} == "" ]];then
            red "鎮ㄨ緭鍏ョ殑python锛�${python_root} 瀵瑰簲鐨刾ip涓嶅彲鐢紝璇锋鏌ユpip鎴栭噸鏂伴€夋嫨鍏朵粬python"
            echo
            return 1
       fi
       pip_version=`$python_root -m pip -V |awk -F '[ .]' '{print $2}'`
       if [[ 9 -le ${pip_version} ]];then
            :
       else
            red "鎮ㄧ殑pip鐗堟湰杩囦綆锛岃瀹夎pip 9.0.1鍙婁互涓婄殑鐗堟湰"
            echo
            return 1
       fi
       if [[ "$python_brief_version" == "" ]];then
            clearMacPythonEnv
            red "鎮ㄧ殑 $python_root 瀵瑰簲鐨刾ip瀛樺湪闂锛岃鎸塩trl + c閫€鍑哄悗閲嶆柊瀹夎pip锛屾垨鍒囨崲鍏朵粬python鐗堟湰"
            echo
            return 1
       else
            if [[ $python_brief_version == "27" ]];then
               uncode=`$python_root -c "import pip._internal;print(pip._internal.pep425tags.get_supported())"|grep "cp27"`
               if [[ $uncode == "" ]];then
                  uncode="mu"
               else
                  uncode="m"
               fi
            fi
            version_list=`echo "${python_list[@]}" | grep "$python_brief_version" `
            if [[ "$version_list" != "" ]];then
               return 0
             else
               red "鏈壘鍒板彲鐢ㄧ殑pip鎴杙ip3銆侾addlePaddle鐩墠鏀寔锛歅ython2.7/3.5/3.6/3.7鍙婂叾瀵瑰簲鐨刾ip, 璇烽噸鏂拌緭鍏ワ紝鎴栦娇鐢╟trl + c閫€鍑�"
               echo
               clearMacPythonEnv
               return 1
            fi

       fi
   fi
}

function checkMacPythonVersion(){
  while true
    do
       read -n1 -p "Step 3. 閫夋嫨Python鐗堟湰锛岃鎸夊洖杞﹂敭缁х画..."
       echo
       yellow "          2. 浣跨敤python 2.x"
       yellow "          3. 浣跨敤python 3.x"
       read -p "          => 璇疯緭鍏ユ暟瀛�2鎴�3銆傚杈撳叆鍏朵粬瀛楃鎴栫洿鎺ュ洖杞︼紝灏嗕細榛樿浣跨敤銆怭ython 2 銆戙€傝鍦ㄨ繖閲岃緭鍏ュ苟鍥炶溅锛�" python_V
       if [[ "$python_V" == "" ]];then
            python_V="2"
       fi
       if [[ "$python_V" == "2" ]];then
            initCheckMacPython2
            if [[ "$?" == "0" ]];then
                checkMacPip
                if [[ "$?" == "0" ]];then
                    return 0
                else
                    :
                fi
            else
                :
            fi
       elif [[ "$python_V" == "3" ]];then
            initCheckMacPython3
            if [[ "$?" == "0" ]];then
                checkMacPip
                if [[ "$?" == "0" ]];then
                    return 0
                else
                    :
                fi
            else
                :
            fi
       else
            red "杈撳叆閿欒锛岃閲嶆柊杈撳叆"
       fi
  done
}


function checkMacGPU(){
    read -n1 -p "Step 5. 閫夋嫨CPU/GPU鐗堟湰锛岃鎸夊洖杞﹂敭缁х画..."
    echo
    if [[ $GPU != "" ]];then
        yellow "          MacOS鐜涓嬶紝鏆傛湭鎻愪緵GPU鐗堟湰鐨凱addlePaddle瀹夎鍖咃紝灏嗕负鎮ㄥ畨瑁匔PU鐗堟湰鐨凱addlePaddle"
    else
        yellow "          MacOS鐜涓嬶紝鏆傛湭鎻愪緵GPU鐗堟湰鐨凱addlePaddle瀹夎鍖咃紝灏嗕负鎮ㄥ畨瑁匔PU鐗堟湰鐨凱addlePaddle"
        GPU=cpu
    fi
    echo
}

function macos() {
  path='http://paddlepaddle.org/download?url='

  while true
      do

        checkMacPaddleVersion

        checkMacPythonVersion

        checkMacGPU


        green "*********************2. 寮€濮嬪畨瑁�*****************************"
        echo
        yellow "鍗冲皢涓烘偍涓嬭浇骞跺畨瑁匬addlePaddle锛岃鎸夊洖杞﹂敭缁х画..."
        read -n1 -p ""
        if [[ $paddle_version == "2" ]];then
            $python_root -m pip install -U  paddlepaddle
            if [[ $? == "0" ]];then
               green "瀹夎鎴愬姛锛屽彲浠ヤ娇鐢�: ${python_root} 鏉ュ惎鍔ㄥ畨瑁呬簡PaddlePaddle鐨凱ython瑙ｉ噴鍣�"
               break
            else
               rm  $whl_cpu_release
               red "鏈兘姝ｅ父瀹夎PaddlePaddle锛岃灏濊瘯鏇存崲鎮ㄨ緭鍏ョ殑python璺緞锛屾垨鑰卌trl + c閫€鍑哄悗璇锋鏌ユ偍浣跨敤鐨刾ython瀵瑰簲鐨刾ip鎴杙ip婧愭槸鍚﹀彲鐢�"
               echo""
               echo "=========================================================================================="
               echo""
               exit 1
            fi
        else
            if [[ -f $whl_cpu_develop ]];then
                $python_root -m pip installi -U $whl_cpu_develop
                if [[ $? == "0" ]];then
                   rm -rf $whl_cpu_develop
                   # TODO add install success check here
                   green "瀹夎鎴愬姛锛佸皬鎻愮ず锛氬彲浠ヤ娇鐢�: ${python_root} 鏉ュ惎鍔ㄥ畨瑁呬簡PaddlePaddle鐨凱ython瑙ｉ噴鍣�"
                   break
                else
                   red "鏈兘姝ｅ父瀹夎PaddlePaddle锛岃灏濊瘯鏇存崲鎮ㄨ緭鍏ョ殑python璺緞锛屾垨鑰卌trl + c閫€鍑哄悗璇锋鏌ユ偍浣跨敤鐨刾ython瀵瑰簲鐨刾ip鎴杙ip婧愭槸鍚﹀彲鐢�"
                   echo""
                   echo "=========================================================================================="
                   echo""
                   exit 1
                fi
            else
                wget ${path}$whl_cpu_develop -O $whl_cpu_develop
                if [[ $? == "0" ]];then
                    $python_root -m pip install $whl_cpu_develop
                    if [[ $? == "0" ]];then
                       rm  $wheel_cpu_develop
                       green "瀹夎鎴愬姛锛屽彲浠ヤ娇鐢�: ${python_root} 鏉ュ惎鍔ㄥ畨瑁呬簡PaddlePaddle鐨凱ython瑙ｉ噴鍣�"
                       break
                    else
                       rm  $whl_cpu_release
                       red "鏈兘姝ｅ父瀹夎PaddlePaddle锛岃灏濊瘯鏇存崲鎮ㄨ緭鍏ョ殑python璺緞锛屾垨鑰卌trl + c閫€鍑哄悗璇锋鏌ユ偍浣跨敤鐨刾ython瀵瑰簲鐨刾ip鎴杙ip婧愭槸鍚﹀彲鐢�"
                       echo""
                       echo "=========================================================================================="
                       echo""
                       exit 1
                    fi
                else
                      rm  $whl_cpu_develop
                      red "鏈兘姝ｅ父瀹夎PaddlePaddle锛岃妫€鏌ユ偍鐨勭綉缁� 鎴栬€呯‘璁ゆ偍鏄惁瀹夎鏈� wget锛屾垨鑰卌trl + c閫€鍑哄悗鍙嶉鑷砲ttps://github.com/PaddlePaddle/Paddle/issues"
                      echo""
                      echo "=========================================================================================="
                      echo""
                      exit 1
                fi
            fi
        fi
  done
}

function main() {
  echo "*********************************"
  green "娆㈣繋浣跨敤PaddlePaddle蹇€熷畨瑁呰剼鏈�"
  echo "*********************************"
  echo
  yellow "濡傛灉鎮ㄥ湪瀹夎杩囩▼涓亣鍒颁换浣曢棶棰橈紝璇峰湪https://github.com/PaddlePaddle/Paddle/issues鍙嶉锛屾垜浠殑宸ヤ綔浜哄憳灏嗕細甯偍绛旂枒瑙ｆ儜"
  echo
  echo  "鏈畨瑁呭寘灏嗗府鍔╂偍鍦↙inux鎴朚ac绯荤粺涓嬪畨瑁匬addlePaddle,鍖呮嫭"
  yellow "1锛夊畨瑁呭墠鐨勫噯澶�"
  yellow "2锛夊紑濮嬪畨瑁�"
  echo
  read -n1 -p "璇锋寜鍥炶溅閿繘琛屼笅涓€姝�..."
  echo
  echo
  green "*********************1. 瀹夎鍓嶇殑鍑嗗*****************************"
  echo
  echo "Step 1. 姝ｅ湪妫€娴嬫偍鐨勬搷浣滅郴缁熶俊鎭�..."
  echo
  SYSTEM=`uname -s`
  if [[ "$SYSTEM" == "Darwin" ]];then
  	yellow "          鎮ㄧ殑绯荤粺涓猴細MAC OSX"
    echo
  	macos
  else
 	yellow "          鎮ㄧ殑绯荤粺涓猴細Linux"
  echo
	  OS=`cat /etc/issue|awk 'NR==1 {print $1}'`
	  if [[ $OS == "\S" ]] || [[ "$OS" == "CentOS" ]] || [[ $OS == "Ubuntu" ]];then
	    linux
	  else
	    red "鎮ㄧ殑绯荤粺涓嶅湪鏈畨瑁呭寘鐨勬敮鎸佽寖鍥达紝濡傛偍闇€瑕佸湪windows鐜涓嬪畨瑁匬addlePaddle锛岃鎮ㄥ弬鑰働addlePaddle瀹樼綉鐨剋indows瀹夎鏂囨。"
	  fi
  fi
}
main