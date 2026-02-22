# Rocky Linux 9 기본 설정

## 0. wsl에 Rock Linx9 설치

1. [Rocky Linux 공식 미러 사이트](https://download.rockylinux.org/pub/rocky/9/images/x86_64/) 에 접속 Rocky-9-WSL-Base.latest.x86_64.wsl 이 파일을 다운로드
2. 윈도우 wsl 버전을 최신버전으로 업데이트

   ```powershell
    wsl -update
    ```

3. Rocky-9-WSL-Base.latest.x86_64.wsl 이 파일의 아이콘이 팽귄으로 변경되면 더블 클릭하여 설치 및 재부팅
4. wsl 에서 설치된 리눅스 목록 확인후 실행

    ```powershell
    # 설치된 리눅스 목록 확인
    wsl -l -v

    # Rocky9 실행
    wsl -d Rocky9

    rocky 시작하는 중...
    Failed to get unit file state for cloud-init.service: No such file or directory
    Please create a default user account. The username does not need to match your Windows username.
    For more information visit: https://aka.ms/wslusers
    Enter new UNIX username: blue
    Your user has been created, is included in the wheel group, and can use sudo without a password.
    To set a password for your user, run 'sudo passwd blue'
    ```

5. 사용자 생성후 아래의 명령으로 패스워드 생성

    ```bash
    sudo passwd username
    ```

## 1. 사전 요구사항 확인

```bash
# 시스템 업데이트
sudo dnf update -y

# 필수 패키지 설치 (wget, git, curl, zsh util-linux-user)
sudo dnf install wget git curl zsh util-linux-user vim mc -y

# 개발자툴 패키지 설치(선택사양)
sudo dnf groupinstall 'Development Tools' -y

# 방화벽 활성화(wsl 환경에서는 불필요)
sudo dnf install firewalld -y
sudo systemctl start firewalld && sudo systemctl enable firewalld
sudo firewall-cmd --state
```

OpenSSH 서버 설치 및 실행

```bash
# OpenSSH 서버 설치 및 서버키 생성(선택사항)
sudo dnf install -y openssh-server 
sudo ssh-keygen -A
```

/etc/ssh/sshd_config 파일 수정
    *root SSH 로그인 차단
    *일반 사용자(user)만 허용
    *비밀번호 인증 허용

```text
PermitRootLogin no
PasswordAuthentication yes
```

```bash
# OpenSSH 서버 실행
sudo systemctl enable sshd
sudo systemctl start sshd
sudo systemctl status sshd
```

## 2. Zsh 설치 및 기본 쉘 설정

```bash
# Zsh 설치 확인
which zsh
# /bin/zsh 출력 확인

# 기본 쉘을 Zsh로 변경 (현재 사용자)
chsh -s $(which zsh)

# 변경 확인 (로그아웃 후 재로그인 필요)
echo $SHELL
```

## 3. Oh My Zsh 설치

```bash
# 공식 설치 스크립트 실행
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended

# 또는 wget 사용
wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh
```

## 4. 플러그인 추가 (선택사항)

터미널 사용 경험을 비약적으로 상승시켜주는 두 가지 플러그인을 추가합니다.

* zsh-autosuggestions: 이전에 쳤던 명령어를 회색으로 미리 보여줍니다.

* zsh-syntax-highlighting: 명령어 오타를 색상으로 구별해 줍니다.

* fzf: fuzzy finder로 파일/히스토리 검색
 
```bash
# 자동 완성 플러그인
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# 구문 강조 플러그인
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# fuzzy finder로 파일/히스토리 검색
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

## 5. 설정 적용 및 테마 변경

```bash
# 테마 변경 (vim 또는 nano 사용)
vim ~/.zshrc
```

`~/.zshrc` 파일에서 다음 줄 수정:

```bash
# 테마 변경
ZSH_THEME="robbyrussell"  # 원하는 테마로 변경 (agnoster, powerlevel10k 등)

# plugins 항목에 추가
plugins=(
  git                     # 내장
  zsh-autosuggestions
  zsh-syntax-highlighting
  podman                  # 내장
  sudo                    # 내장
  fzf
)
```

```bash
# 설정 파일 로드
source ~/.zshrc
```

테마 목록: [Oh My Zsh Themes](https://github.com/ohmyzsh/ohmyzsh/wiki/Themes) [gist.github](https://gist.github.com/ebell451/f4eca64951a1585a6d0b65a293d328a4)

## 6. 다중라인 쉘 프롬프트(선택사항)

```bash
vim ~/.oh-my-zsh/themes/agnoster.zsh-theme
```

```bash
## NewLine                              // 추가 
prompt_newline() {
if [[ -n $CURRENT_BG ]]; then
    echo -n "%{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR
%(?.%F{$CURRENT_BG}.%F{red})❯%f"

else
    echo -n "%{%k%}"
fi

echo -n "%{%f%}"
CURRENT_BG=''
}

## Main prompt                          // 수정                     
build_prompt() {
RETVAL=$?
prompt_status
prompt_virtualenv
prompt_aws
prompt_context
prompt_dir
prompt_git
prompt_bzr
prompt_hg
prompt_newline                          // <-- add
prompt_end
}
```

```bash
# 설정 파일 로드
source ~/.zshrc
```

## 7. WSL Interop(상호운용성) 활성화

Rocky Linux 터미널에서 아래 명령어를 입력해 설정 파일을 확인합니다.

```bash
cat /proc/sys/fs/binfmt_misc/WSLInterop
```

만약 **enabled**가 보이지 않거나 파일이 없다고 나온다면 설정이 꺼져 있는 것입니다.

/etc/wsl.conf 파일을 수정합니다 (없으면 생성).

```bash
sudo vim /etc/wsl.conf
```

아래 내용을 추가하고 저장합니다.

```Ini, TOML
[interop]
enabled=true
appendWindowsPath=true
```

중요: 설정을 적용하려면 윈도우 파워셸에서 **wsl --shutdown**를 입력해 완전히 껐다 켜야 합니다.

## 문제 해결

| 문제 | 해결방법 |
| --- | --- |
| `chsh: users can only change the shell for their own account` | `sudo chsh -s /bin/zsh $USER` |
| 설정이 적용 안됨 | 로그아웃/재로그인 또는 `exec zsh` |
| 권한 오류 | `sudo chown -R $USER:$USER ~/.oh-my-zsh` |

## 검증

```bash
# Zsh 버전 확인
zsh --version

# Oh My Zsh 확인
ls -la ~/.oh-my-zsh
```

**완료!** 터미널을 재시작하면 Oh My Zsh가 적용됩니다. [gist.github](https://gist.github.com/ebell451/f4eca64951a1585a6d0b65a293d328a4)
