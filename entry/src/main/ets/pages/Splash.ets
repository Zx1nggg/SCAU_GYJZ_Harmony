import router from '@ohos.router';

@Entry
@Component
struct Splash {
  aboutToAppear() {
    // 延迟 2.5 秒后跳转到首页
    setTimeout(() => {
      router.replaceUrl({
        url: 'pages/Index'
      });
    }, 2500);
  }

  build() {
    Column() {
      // 顶部留白 
      Blank()

      // 配合圆形图标，去掉了之前的白色粗边框，改为轻微的弥散阴影
      Image($r('app.media.startIcon'))
        .width(100)
        .height(100)
        .margin({ bottom: 24 })
        .borderRadius(50) // 设为 50 刚好是完美的圆形
        .shadow({ radius: 15, color: 'rgba(0,0,0,0.08)', offsetY: 5 })

      // 主标语：因为背景变白了，文字必须改成深色（#333333）
      Text('让爱传递 · 点亮希望')
        .fontSize(28)
        .fontWeight(FontWeight.Bolder)
        .fontColor('#333333')
        .letterSpacing(3)

      // 副标语：使用中灰色
      Text('SCAU 公益捐赠服务平台')
        .fontSize(16)
        .fontColor('#666666')
        .margin({ top: 12 })
        .letterSpacing(1)

      // 底部留白
      Blank()

      // 版权信息：使用浅灰色
      Text('SCAU Team 11 版权所有')
        .fontSize(12)
        .fontColor('#BDBDBD')
        .margin({ bottom: 40 })
    }
    .width('100%')
    .height('100%')
    // 去掉 linearGradient，改回纯白背景
    .backgroundColor('#FFFFFF')
    .alignItems(HorizontalAlign.Center)
  }
}