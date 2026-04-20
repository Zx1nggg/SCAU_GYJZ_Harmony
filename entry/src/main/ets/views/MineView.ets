import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

@Component
export struct MineView {
  @StorageLink('isLoggedIn') isLoggedIn: boolean = false;
  @StorageLink('nickname') nickname: string = '';
  @StorageLink('phone') phone: string = '';
  @StorageLink('avatar') avatar: string = '';

  // 1. 完善退出登录逻辑
  handleLogout() {
    AppStorage.SetOrCreate('isLoggedIn', false);
    AppStorage.SetOrCreate('token', '');
    AppStorage.SetOrCreate('nickname', '');
    AppStorage.SetOrCreate('phone', '');
    AppStorage.SetOrCreate('userId', 0);
    AppStorage.SetOrCreate('avatar', '');

    promptAction.showToast({ message: '已安全退出登录' });
  }

  // 2. 封装安全的路由跳转方法
  safePushUrl(targetUrl: string) {
    router.pushUrl({ url: targetUrl }).catch((err: Error) => {
      console.error(`[MineView] 路由跳转异常: ${err.message}`);
      promptAction.showToast({ message: '页面开发中或配置错误' });
    });
  }

  build() {
    Column() {
      // 顶部资料卡
      Column() {
        if (this.isLoggedIn) {
          Image(this.avatar ? `http://192.168.1.102:8080${this.avatar}` : $r('app.media.startIcon'))
            .width(76).height(76)
            .borderRadius(38)
            .margin({ bottom: 12 })
            .border({ width: 2, color: 'rgba(255,255,255,0.8)' })
            .objectFit(ImageFit.Cover)

          Text(this.nickname || this.phone || '爱心人士')
            .fontSize(22).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')

          Text(this.phone)
            .fontSize(14).fontColor('rgba(255,255,255,0.8)').margin({ top: 6 })
            .backgroundColor('rgba(0,0,0,0.1)').padding({ left: 10, right: 10, top: 4, bottom: 4 }).borderRadius(12)
        } else {
          Image($r('app.media.startIcon'))
            .width(76).height(76).borderRadius(38).margin({ bottom: 15 }).opacity(0.6)
          Text('未登录').fontSize(22).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
          Button('点击登录 / 注册')
            .backgroundColor('#FFFFFF').fontColor('#FF7E5F').margin({ top: 15 }).fontWeight(FontWeight.Bold)
            .onClick(() => {
              this.safePushUrl('pages/Login');
            })
        }
      }
      .width('100%')
      .height(280)
      .linearGradient({
        angle: 180,
        colors: [['#FF7E5F', 0.0], ['#FEB47B', 1.0]]
      })
      .justifyContent(FlexAlign.Center)
      .padding({ top: 20 })

      // 菜单面板
      if (this.isLoggedIn) {
        Column() {
          this.MenuRow(
            'https://api.iconify.design/solar:notes-bold-duotone.svg?color=%23FF7E5F',
            '我的捐赠记录',
            () => { this.safePushUrl('pages/MyDonations'); }
          )
          Divider().color('#F5F5F5').margin({ left: 50, right: 20 })

          // 我的订阅入口
          this.MenuRow(
            'https://api.iconify.design/solar:star-bold-duotone.svg?color=%23FF7E5F',
            '我订阅的项目',
            () => { this.safePushUrl('pages/MySubscriptions'); }
          )
          Divider().color('#F5F5F5').margin({ left: 50, right: 20 })

          this.MenuRow(
            'https://api.iconify.design/solar:pen-new-square-bold-duotone.svg?color=%23FF7E5F',
            '修改个人资料',
            () => { this.safePushUrl('pages/EditProfile'); }
          )
          Divider().color('#F5F5F5').margin({ left: 50, right: 20 })

          this.MenuRow(
            'https://api.iconify.design/solar:logout-2-bold-duotone.svg?color=%23FF7E5F',
            '退出登录',
            () => { this.handleLogout(); }
          )
        }
        .width('92%')
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .margin({ top: -30 })
        .padding({ top: 10, bottom: 10 })
        .shadow({ radius: 20, color: 'rgba(255,126,95,0.1)', offsetY: 5 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA')
  }

  @Builder MenuRow(iconUrl: string, title: string, action: () => void) {
    Row() {
      Image(iconUrl).width(24).height(24).margin({ right: 15 })
      Text(title).fontSize(16).fontColor('#333333').fontWeight(FontWeight.Medium).layoutWeight(1)
      Image('https://api.iconify.design/solar:alt-arrow-right-linear.svg?color=%23CCCCCC').width(20).height(20)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 18, bottom: 18 })
    .onClick(action)
  }
}