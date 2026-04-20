import router from '@ohos.router';
import HttpUtil, { BaseResponse } from '../utils/HttpUtil';

// 修复 ArkTS 严格模式报错：声明 POST 请求实体类
class SubscribePayload {
  userId: number;
  projectId: number;
  constructor(userId: number, projectId: number) {
    this.userId = userId;
    this.projectId = projectId;
  }
}

class DonationPayload {
  projectId: number;
  userId: number;
  donorName: string;
  donorPhone: string;
  amount: number;
  remark: string;
  donationStatus: number;
  source: number;
  payment: string;
  donorTime: string;

  constructor(projectId: number, userId: number, donorName: string, donorPhone: string, amount: number, remark: string) {
    this.projectId = projectId;
    this.userId = userId;
    this.donorName = donorName;
    this.donorPhone = donorPhone;
    this.amount = amount;
    this.remark = remark;
    this.donationStatus = 1;
    this.source = 1;
    this.payment = '模拟支付';
    this.donorTime = new Date().toISOString();
  }
}

// 弹窗组件：模拟支付
@CustomDialog
struct DonateDialog {
  controller?: CustomDialogController;
  @State amount: string = '';
  @State remark: string = '';

  confirmAction?: (amount: number, remark: string) => void;

  build() {
    Column() {
      Text('爱心捐赠').fontSize(20).fontWeight(FontWeight.Bold).margin({ bottom: 20 })

      TextInput({ placeholder: '请输入捐赠金额 (元)' })
        .type(InputType.Number)
        .onChange((value) => { this.amount = value; })
        .width('100%')
        .height(50)
        .margin({ bottom: 15 })
        .backgroundColor('#F5F7FA')

      TextInput({ placeholder: '爱心寄语 (选填)' })
        .onChange((value) => { this.remark = value; })
        .width('100%')
        .height(50)
        .margin({ bottom: 20 })
        .backgroundColor('#F5F7FA')

      Row() {
        Button('取消').backgroundColor('#F0F0F0').fontColor('#666').layoutWeight(1)
          .onClick(() => { this.controller?.close() })
        Blank().width(15)
        Button('确认支付').backgroundColor('#FF7E5F').fontColor('#FFF').layoutWeight(1)
          .onClick(() => {
            let numAmount = parseFloat(this.amount);
            if (isNaN(numAmount) || numAmount <= 0) {
              this.getUIContext().getPromptAction().showToast({ message: '请输入有效金额' });
              return;
            }
            if (this.confirmAction) {
              this.confirmAction(numAmount, this.remark);
              this.controller?.close();
            }
          })
      }.width('100%')
    }.padding(20).backgroundColor('#FFF').borderRadius(16)
  }
}

@Entry
@Component
struct ProjectDetail {
  @State projectId: number = 0;
  @State projectInfo: Record<string, Object> = {};
  @State loading: boolean = true;

  // 新增订阅状态
  @State isSubscribed: boolean = false;

  dialogController: CustomDialogController = new CustomDialogController({
    builder: DonateDialog({
      confirmAction: (amount: number, remark: string) => { this.executeDonation(amount, remark) }
    }),
    alignment: DialogAlignment.Bottom,
    offset: { dx: 0, dy: -20 }
  });

  aboutToAppear() {
    let params = router.getParams() as Record<string, number>;
    if (params && params['id']) {
      this.projectId = params['id'];
      this.loadDetail();
      this.checkSubscriptionStatus(); // 初始化时查询是否已订阅
    }
  }

  async loadDetail() {
    try {
      let res: BaseResponse = await HttpUtil.get(`/projects/${this.projectId}`);
      if (res.code === 200 && res.data) {
        this.projectInfo = res.data as Record<string, Object>;
        console.info("======= 鸿蒙端收到的后端项目数据: " + JSON.stringify(this.projectInfo));
      }
    } catch (e) {
      console.error("加载详情失败");
    } finally {
      this.loading = false;
    }
  }

  // 查询订阅状态
  async checkSubscriptionStatus() {
    let userId = AppStorage.Get<number>('userId');
    if (!userId) return;

    try {
      let res: BaseResponse = await HttpUtil.get(`/subscriptions/status?userId=${userId}&projectId=${this.projectId}`);
      if (res.code === 200) {
        this.isSubscribed = res.data as boolean;
      }
    } catch (e) {
      console.error("[ProjectDetail] 查询订阅状态异常");
    }
  }

  // 切换订阅状态
  async toggleSubscribe() {
    let userId = AppStorage.Get<number>('userId');
    if (!userId) {
      this.getUIContext().getPromptAction().showToast({ message: '请先登录' });
      router.pushUrl({ url: 'pages/Login' });
      return;
    }

    try {
      if (this.isSubscribed) {
        // 取消订阅
        let res: BaseResponse = await HttpUtil.delete(`/subscriptions?userId=${userId}&projectId=${this.projectId}`);
        if (res.code === 200) {
          this.isSubscribed = false;
          this.getUIContext().getPromptAction().showToast({ message: '已取消订阅' });
        }
      } else {
        // 新增订阅，使用 Payload 类修复严格模式报错
        let payload = new SubscribePayload(userId, this.projectId);
        let res: BaseResponse = await HttpUtil.post(`/subscriptions`, payload);
        if (res.code === 200) {
          this.isSubscribed = true;
          this.getUIContext().getPromptAction().showToast({ message: '订阅成功！有新动态将通知您' });
        }
      }
    } catch (e) {
      this.getUIContext().getPromptAction().showToast({ message: '网络请求失败' });
    }
  }

  checkIsFinished(): boolean {
    if (!this.projectInfo) return false;
    let status = Number(this.projectInfo['projectStatus'] || 0);
    let currentAmount = Number(this.projectInfo['currentAmount'] || 0);
    let targetAmount = Number(this.projectInfo['targetAmount'] || 0);
    return status === 2 || (targetAmount > 0 && currentAmount >= targetAmount);
  }

  handleDonateClick() {
    let isLoggedIn = AppStorage.Get<boolean>('isLoggedIn');
    let token = AppStorage.Get<string>('token');

    if (!isLoggedIn || !token) {
      this.getUIContext().getPromptAction().showToast({ message: '请先登录后再进行捐赠操作', duration: 2000 });
      router.pushUrl({ url: 'pages/Login' });
    } else {
      this.dialogController.open();
    }
  }

  async executeDonation(amount: number, remark: string) {
    try {
      let userId = AppStorage.Get<number>('userId') || 0;
      let phone = AppStorage.Get<string>('phone') || '';
      let nickname = AppStorage.Get<string>('nickname') || '爱心人士';

      // 使用 DonationPayload 类实例化对象，修复 ArkTS 不能直接传对象的报错
      let payload = new DonationPayload(this.projectId, userId, nickname, phone, amount, remark);

      let res: BaseResponse = await HttpUtil.post('/donations/create', payload);

      if (Number(res.code) === 200) {
        this.getUIContext().getPromptAction().showToast({ message: '捐赠成功，感谢您的爱心！' });
        setTimeout(() => { this.loadDetail(); }, 1000);
      } else {
        this.getUIContext().getPromptAction().showToast({ message: res.msg || '捐赠失败' });
      }
    } catch (e) {
      console.error('[ProjectDetail] 捐赠请求异常: ' + JSON.stringify(e));
      this.getUIContext().getPromptAction().showToast({ message: '网络请求失败' });
    }
  }

  build() {
    Column() {
      // 顶部导航
      Row() {
        Image('https://api.iconify.design/solar:alt-arrow-left-linear.svg?color=%23333333')
          .width(28).height(28)
          .onClick(() => { router.back() })
        Text('项目详情').fontSize(18).fontWeight(FontWeight.Bold).margin({ left: 10 })
      }.width('100%').height(56).padding({ left: 15 }).backgroundColor('#FFFFFF').zIndex(2)

      if (this.loading) {
        LoadingProgress().width(50).height(50).margin({ top: 100 })
      } else {
        Scroll() {
          Column() {
            Image(this.projectInfo['coverImage'] ? `http://192.168.59.89:8080${this.projectInfo['coverImage']}` : $r('app.media.startIcon'))
              .width('100%').height(220).objectFit(ImageFit.Cover)

            Column() {
              Text(this.projectInfo['title'] as string).fontSize(22).fontWeight(FontWeight.Bold).margin({ top: 15 })

              Row() {
                Text(`目标: ¥${this.projectInfo['targetAmount']}`).fontColor('#FF7E5F').fontSize(16).fontWeight(FontWeight.Bold)
                Blank()
                Text(`已筹: ¥${this.projectInfo['currentAmount']}`).fontColor('#666666').fontSize(14)
              }.width('100%').margin({ top: 15 })

              // 展示机构名称、开始和结束时间
              Column() {
                Row() {
                  Image('https://api.iconify.design/solar:buildings-2-bold-duotone.svg?color=%23999999')
                    .width(18).height(18).margin({ right: 8 })

                  Text(`发起机构: ${this.projectInfo['orgName'] as String || '公益组织'}`)
                    .fontSize(14).fontColor('#666666')
                }.width('100%').margin({ bottom: 8 })

                Row() {
                  Image('https://api.iconify.design/solar:calendar-date-bold-duotone.svg?color=%23999999')
                    .width(18).height(18).margin({ right: 8 })
                  Text(`项目周期: ${this.projectInfo['startDate'] ? String(this.projectInfo['startDate']).substring(0, 10) : '未知'} 至 ${this.projectInfo['endDate'] ? String(this.projectInfo['endDate']).substring(0, 10) : '未知'}`)
                    .fontSize(14).fontColor('#666666')
                }.width('100%')
              }
              .width('100%')
              .padding(15)
              .backgroundColor('#F7F8FA')
              .borderRadius(10)
              .margin({ top: 20 })

              Divider().margin({ top: 20, bottom: 20 }).color('#F0F0F0')

              Text('项目详情').fontSize(18).fontWeight(FontWeight.Bold).margin({ bottom: 10 })
              Text(this.projectInfo['content'] as string).fontSize(15).fontColor('#555').lineHeight(26)
            }.padding(20).alignItems(HorizontalAlign.Start)
          }
        }.layoutWeight(1).edgeEffect(EdgeEffect.Spring)

        // 重构的底部按钮区 (包含订阅和捐款)
        Row() {
          // 订阅按钮区
          Column() {
            Image(this.isSubscribed
              ? 'https://api.iconify.design/solar:star-bold.svg?color=%23FFB300'
              : 'https://api.iconify.design/solar:star-linear.svg?color=%23666666')
              .width(24).height(24)
            Text(this.isSubscribed ? '已订阅' : '订阅')
              .fontSize(12)
              .fontColor(this.isSubscribed ? '#FFB300' : '#666666')
              .margin({ top: 4 })
          }
          .width('20%')
          .justifyContent(FlexAlign.Center)
          .onClick(() => { this.toggleSubscribe(); })

          Button(this.checkIsFinished() ? '项目已圆满结束' : '立即捐款')
            .layoutWeight(1)
            .height(44)
            .margin({ right: 15 })
            .backgroundColor(this.checkIsFinished() ? '#CCCCCC' : '#FF7E5F')
            .fontColor('#FFFFFF')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .enabled(!this.checkIsFinished())
            .onClick(() => {
              this.handleDonateClick();
            })
        }.width('100%').height(65).alignItems(VerticalAlign.Center).backgroundColor('#FFFFFF').shadow({ radius: 10, color: 'rgba(0,0,0,0.05)', offsetY: -5 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}