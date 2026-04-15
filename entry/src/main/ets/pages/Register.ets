import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import HttpUtil, { BaseResponse } from '../utils/HttpUtil';

@Entry
@Component
struct Register {
  @State phone: string = '';
  @State code: string = '';
  @State password: string = '';

  @State loading: boolean = false;
  @State countdown: number = 0; // 倒计时
  private timer: number = -1;

  // 模拟发送验证码
  sendCode() {
    if (!/^1[3-9]\d{9}$/.test(this.phone)) {
      promptAction.showToast({ message: '请输入正确的手机号' });
      return;
    }
    this.countdown = 60;
    promptAction.showToast({ message: '验证码已发送 (模拟:1234)' });

    this.timer = setInterval(() => {
      if (this.countdown > 0) {
        this.countdown--;
      } else {
        clearInterval(this.timer);
      }
    }, 1000);
  }

  async handleRegister() {
    if (!this.phone || !this.code || !this.password) {
      promptAction.showToast({ message: '请完整填写信息' });
      return;
    }

    // 模拟校验验证码
    if (this.code !== '1234') {
      promptAction.showToast({ message: '验证码错误 (请输入1234)' });
      return;
    }

    this.loading = true;
    try {
      let payload: Record<string, string> = {
        'phone': this.phone,
        'password': this.password
      };

      let res: BaseResponse = await HttpUtil.post('/donor/Register', payload);

      if (res.code === 200) {
        promptAction.showToast({ message: '注册成功，请登录' });
        router.back(); // 返回登录页
      } else {
        promptAction.showToast({ message: res.msg || '注册失败' });
      }
    } catch (e) {
      promptAction.showToast({ message: '网络错误或服务器异常' });
    } finally {
      this.loading = false;
    }
  }

  build() {
    Column() {
      // 顶部返回
      Row() {
        Image('https://api.iconify.design/solar:alt-arrow-left-linear.svg?color=%23333333')
          .width(32).height(32)
          .onClick(() => { router.back() })
      }.width('100%').padding(20).justifyContent(FlexAlign.Start)

      // 标题
      Column() {
        Text('加入我们').fontSize(28).fontWeight(FontWeight.Bold).fontColor('#333333')
        Text('注册成为爱心捐赠人').fontSize(14).fontColor('#999999').margin({ top: 10 })
      }.width('100%').alignItems(HorizontalAlign.Start).padding({ left: 30, right: 30, top: 10, bottom: 40 })

      // 表单
      Column({ space: 20 }) {
        TextInput({ placeholder: '请输入手机号' })
          .type(InputType.PhoneNumber)
          .maxLength(11)
          .height(50)
          .backgroundColor('#F5F7FA')
          .onChange((value: string) => { this.phone = value })

        Row() {
          TextInput({ placeholder: '验证码 (模拟1234)' })
            .type(InputType.Number)
            .maxLength(6)
            .height(50)
            .backgroundColor('#F5F7FA')
            .layoutWeight(1)
            .onChange((value: string) => { this.code = value })

          Button(this.countdown > 0 ? `${this.countdown}s 后重发` : '获取验证码')
            .height(50)
            .backgroundColor(this.countdown > 0 ? '#E0E0E0' : '#FF7E5F')
            .fontColor(this.countdown > 0 ? '#999999' : '#FFFFFF')
            .margin({ left: 10 })
            .enabled(this.countdown === 0)
            .onClick(() => { this.sendCode() })
        }.width('100%')

        TextInput({ placeholder: '请设置密码' })
          .type(InputType.Password)
          .height(50)
          .backgroundColor('#F5F7FA')
          .onChange((value: string) => { this.password = value })

        Button(this.loading ? '注册中...' : '注 册')
          .width('100%')
          .height(50)
          .backgroundColor('#FF7E5F')
          .fontColor('#FFFFFF')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20 })
          .onClick(() => { this.handleRegister() })
      }.padding({ left: 30, right: 30 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}