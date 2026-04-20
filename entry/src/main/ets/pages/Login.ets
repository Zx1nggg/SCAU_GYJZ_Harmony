import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import HttpUtil, { BaseResponse } from '../utils/HttpUtil';
import pushService from '@hms.core.push.pushService';

@Entry
@Component
struct Login {
  @State phone: string = '';
  @State password: string = '';
  @State loading: boolean = false;

  // 1. 定义一个状态触发器，通过 @Watch 强制桥接回 UI 主线程
  @State @Watch('onLoginSuccess') loginSuccessTrigger: boolean = false;

  // 2. 这里的代码由状态改变触发，100% 保证在绝对安全的 UI 主线程运行！
  onLoginSuccess() {
    if (this.loginSuccessTrigger) {
      console.info('[Login] @Watch 触发，成功回到 UI 主线程，拥有完整的执行上下文！');

      try {
        // 彻底干掉 setTimeout！
        // 顺序翻转：先跳转，后弹窗！这样完美避开死锁，且绝对不会因为 setTimeout 丢失 UI 上下文！
        let stackLength = parseInt(router.getLength());
        console.info('[Login] UI线程 - 页面栈深度: ' + stackLength);

        if (stackLength > 1) {
          console.info('[Login] UI线程 - 执行 router.back()');
          router.back();
        } else {
          console.info('[Login] UI线程 - 栈太浅，执行 router.replaceUrl()');
          router.replaceUrl({ url: 'pages/Index' });
        }

        // 跳转指令发出后，紧接着弹窗（此时新页面刚好压栈或回退，Toast 会在顶层完美展示）
        promptAction.showToast({ message: '登录成功，SCAU公益感谢您的每一笔捐款~' });

      } catch (routeErr) {
        let e = routeErr as Error;
        console.error(' [Login] UI线程跳转异常: ' + e.message);
        // 极度异常情况下的终极兜底
        try { router.replaceUrl({ url: 'pages/Index' }); } catch(ex){}
      }
    }
  }

  async handleLogin() {
    if (!this.phone || !this.password) {
      promptAction.showToast({ message: '请填写手机号和密码' });
      return;
    }

    if (!/^1[3-9]\d{9}$/.test(this.phone)) {
      promptAction.showToast({ message: '请输入正确的手机号' });
      return;
    }

    this.loading = true;
    let loginSuccess = false;
    console.info('[Login] 开始发起登录请求...');

    try {
      let payload: Record<string, string> = {
        'phone': this.phone,
        'password': this.password
      };

      let res: BaseResponse = await HttpUtil.post('/donor/Login', payload);

      console.info('[Login] 后端返回结果: ' + JSON.stringify(res));
      let resCode = Number(res.code);

      if (resCode === 200) {
        console.info('[Login] 密码验证通过！');
        loginSuccess = true;

        let userId: number = 0; // 用于保存提取出来的用户ID

        if (res.data !== undefined && res.data !== null) {
          let userData = res.data as Record<string, Object>;

          let token = userData['token'] ? String(userData['token']) : '';
          let userPhone = userData['phone'] ? String(userData['phone']) : this.phone;
          let nickname = userData['nickname'] ? String(userData['nickname']) : '爱心人士';
          userId = userData['id'] as number; // 提取 userId，用于绑定 Token
          let avatar = userData['avatar'] ? String(userData['avatar']) : '';

          AppStorage.SetOrCreate('token', token);
          AppStorage.SetOrCreate('phone', userPhone);
          AppStorage.SetOrCreate('nickname', nickname);
          AppStorage.SetOrCreate('userId', userId);
          AppStorage.SetOrCreate('avatar', avatar);
          AppStorage.SetOrCreate('isLoggedIn', true);


          console.info('[Login] 全局状态保存成功！准备获取 Push Token...');
        }

        // 3. 获取华为 Push Token 并上报给后端
        if (userId) {
          try {
            // 尝试向华为系统申请真实的设备推送 Token
            let pushTokenStr = await pushService.getToken();

            if (!pushTokenStr || pushTokenStr.trim() === '') {
              console.warn('获取到了空 Token，强制转入 Mock 逻辑');
              throw new Error("Empty Push Token"); // 强制抛出异常，进入 catch 块！
            }

            let tokenPayload: Record<string, string> = {
              'pushToken': pushTokenStr
            };
            console.info('获取真实 Push Token 成功: ' + pushTokenStr);

            let resPut = await HttpUtil.put(`/users/${userId}/token`, tokenPayload);
            console.info('[真实设备] 上报结果: ' + JSON.stringify(resPut));

          } catch (pushErr) {
            // 降级处理：在预览器或普通模拟器中会走到这里
            console.warn(' 获取真实 Token 失败/为空，走入预览器 Mock 分支');
            let mockToken = `mock_hm_token_${this.phone}`;
            let mockPayload: Record<string, string> = {
              'pushToken': mockToken
            };

            // 同样确保路径正确，并打印结果
            let resPut = await HttpUtil.put(`/users/${userId}/token`, mockPayload);
            console.info('[预览器Mock] 上报结果: ' + JSON.stringify(resPut));
          }
        }

        // 4. 触发 @Watch 桥接，回到主线程执行安全跳转！
        this.loginSuccessTrigger = true;

        return; // 终止异步函数的往下执行

      } else {
        console.warn('[Login] 登录失败，后端 code: ' + res.code);
        promptAction.showToast({ message: res.msg || '登录失败，请检查账号密码' });
      }
    } catch (e) {
      let err = e as Error;
      console.error('[Login] 捕获到超级异常: ', err.message || JSON.stringify(e));
      try {
        promptAction.showToast({ message: '网络错误或服务器异常' });
      } catch (toastErr) {}
    } finally {
      if (!loginSuccess) {
        this.loading = false;
      }
    }
  }

  build() {
    Column() {
      // 顶部返回按钮
      Row() {
        Image('https://api.iconify.design/solar:alt-arrow-left-linear.svg?color=%23333333')
          .width(32).height(32)
          .onClick(() => {
            router.back();
          })
      }.width('100%').padding(20).justifyContent(FlexAlign.Start)

      // 页面标题
      Column() {
        Image($r('app.media.startIcon')).width(80).height(80).borderRadius(40).margin({ bottom: 20 })
        Text('欢迎回来').fontSize(28).fontWeight(FontWeight.Bold).fontColor('#333333')
        Text('登录以继续传递爱心').fontSize(14).fontColor('#999999').margin({ top: 10 })
      }.width('100%').alignItems(HorizontalAlign.Start).padding({ left: 30, right: 30, top: 20, bottom: 40 })

      // 输入表单
      Column({ space: 20 }) {
        TextInput({ placeholder: '请输入手机号' })
          .type(InputType.PhoneNumber)
          .maxLength(11)
          .height(50)
          .backgroundColor('#F5F7FA')
          .onChange((value: string) => { this.phone = value })

        TextInput({ placeholder: '请输入密码' })
          .type(InputType.Password)
          .height(50)
          .backgroundColor('#F5F7FA')
          .onChange((value: string) => { this.password = value })
          .onSubmit(() => { this.handleLogin() })

        Button(this.loading ? '登录中...' : '登 录')
          .width('100%')
          .height(50)
          .backgroundColor('#FF7E5F')
          .fontColor('#FFFFFF')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20 })
          .onClick(() => { this.handleLogin() })
      }.padding({ left: 30, right: 30 })

      Blank()

      // 底部注册入口
      Row() {
        Text('还没有账号？').fontColor('#999999').fontSize(14)
        Text('立即注册')
          .fontColor('#FF7E5F')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .onClick(() => {
            router.pushUrl({ url: 'pages/Register' })
          })
      }.margin({ bottom: 40 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}