import HttpUtil, { BaseResponse } from '../utils/HttpUtil';
import router from '@ohos.router';

// 1. 严格对齐 push_record 表的数据模型
export interface PushRecord {
  id: number;
  userId: number;
  projectId?: number;
  title: string;
  content: string;
  type: number;      // 1-项目进度，2-新项目，3-项目完成
  sendTime: string;  // 对应 send_time
  sendStatus: number;// 1-成功，2-失败
}

@Component
export struct NotificationView {
  @State messages: PushRecord[] = [];
  @State isLoading: boolean = true;

  // 从全局获取用户登录状态
  @StorageLink('userId') userId: number = 0;
  // 核心修复：添加 @Watch 监听全局登录状态变化
  @StorageLink('isLoggedIn') @Watch('onLoginStateChange') isLoggedIn: boolean = false;

  // 新增：当 isLoggedIn 发生改变时，自动触发这个函数
  onLoginStateChange() {
    console.info(`[NotificationView] 监听到登录状态发生改变: isLoggedIn=${this.isLoggedIn}`);
    // 如果变成了已登录状态，立刻重新拉取数据！
    if (this.isLoggedIn && this.userId !== 0) {
      this.loadMessages();
    }
  }

  aboutToAppear() {
    this.loadMessages();
  }

  // 2. 向后端请求推送记录列表
  async loadMessages() {
    console.info('[诊断] 准备拉取消息... 当前状态: isLoggedIn=', this.isLoggedIn, ', userId=', this.userId);

    if (!this.isLoggedIn || !this.userId) {
      console.warn('[诊断] 拦截：用户未登录或 userId 为空！');
      this.isLoading = false;
      return;
    }

    try {
      this.isLoading = true;
      let queryParams: Record<string, number> = { 'userId': this.userId };

      // 盲点 1：检查接口路径是否少加了 /api/v1 ？
      // 如果你的其他接口都是 /api/v1/xxx，这里可能需要改成 /api/v1/push/my
      let url = '/push/my';
      console.info(`[诊断] 发起请求: GET ${url} , 参数:`, JSON.stringify(queryParams));

      let res: BaseResponse = await HttpUtil.get(url, queryParams);
      console.info('[诊断] 后端返回完整结果: ' + JSON.stringify(res));

      if (Number(res.code) === 200 && res.data) {
        let pageData = res.data as Record<string, Object>;

        if (pageData['records']) {
          this.messages = pageData['records'] as PushRecord[];
          console.info('[诊断] 成功解析分页 records，共: ' + this.messages.length + ' 条');
        } else if (Array.isArray(res.data)) {
          this.messages = res.data as PushRecord[];
          console.info('[诊断] 成功解析数组格式，共: ' + this.messages.length + ' 条');
        } else {
          console.warn('[诊断] 数据格式不匹配！既没有 records 字段，也不是数组。');
        }
      } else {
        console.warn('[诊断] 后端返回状态码不是 200，或者 data 为空！');
      }
    } catch (e) {
      console.error('[NotificationView] 拉取消息失败: ' + JSON.stringify(e));
    } finally {
      this.isLoading = false;
    }
  }

  // 3. 辅助方法：将 sendTime 转换为 "10分钟前"
  formatRelativeTime(dateStr: string): string {
    if (!dateStr) return '';
    let date = new Date(dateStr);
    let now = new Date();
    let diffMs = now.getTime() - date.getTime();
    let diffMins = Math.floor(diffMs / 60000);
    let diffHours = Math.floor(diffMins / 60);
    let diffDays = Math.floor(diffHours / 24);

    if (diffMins < 1) return '刚刚';
    if (diffMins < 60) return `${diffMins}分钟前`;
    if (diffHours < 24) return `${diffHours}小时前`;
    if (diffDays === 1) return '昨天';
    if (diffDays < 30) return `${diffDays}天前`;

    return `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')}`;
  }

  // 4. 辅助方法：根据 type 字段返回标签文本和颜色
  getTypeTagConfig(type: number): Record<string, string> {
    switch (type) {
      case 1: // 项目进度
        return { 'label': '项目进度', 'bgColor': '#E6F4FF', 'textColor': '#1677FF' } as Record<string, string>;
      case 2: // 新项目
        return { 'label': '上新', 'bgColor': '#F6FFED', 'textColor': '#52C41A' } as Record<string, string>;
      case 3: // 捐赠成功
        return { 'label': '捐赠成功', 'bgColor': '#FFF0E6', 'textColor': '#FF7E5F' } as Record<string, string>;
      default:
        return { 'label': '系统', 'bgColor': '#F5F5F5', 'textColor': '#666666' } as Record<string, string>;
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('消息通知')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
      }
      .width('100%')
      .height(56)
      .padding({ left: 20 })
      .backgroundColor('#FFFFFF')
      .shadow({ radius: 10, color: 'rgba(0,0,0,0.03)', offsetY: 2 })
      .zIndex(1)

      // 核心列表区域
      if (this.isLoading) {
        LoadingProgress().width(50).height(50).margin({ top: 100 })
      } else if (!this.isLoggedIn) {
        Column() {
          Image('https://api.iconify.design/solar:lock-password-unlocked-duotone.svg?color=%23CCCCCC').width(80).height(80)
          Text('登录后即可查看消息通知').fontColor('#999999').margin({ top: 15, bottom: 20 })
          Button('前往登录').backgroundColor('#FF7E5F').onClick(() => { router.pushUrl({ url: 'pages/Login' }) })
        }.margin({ top: 120 })
      } else if (this.messages.length === 0) {
        Column() {
          Image('https://api.iconify.design/solar:bell-bing-duotone.svg?color=%23CCCCCC').width(80).height(80)
          Text('暂无新消息').fontColor('#999999').margin({ top: 15 })
        }.margin({ top: 120 })
      } else {
        List({ space: 12 }) {
          ForEach(this.messages, (item: PushRecord) => {
            ListItem() {
              Column() {
                Row() {
                  // 修复 ArkTS 报错：UI 声明语句块内不能写 let 变量定义，必须直接通过函数调用拿值
                  Text(this.getTypeTagConfig(item.type)['label'])
                    .fontSize(10)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.getTypeTagConfig(item.type)['textColor'])
                    .backgroundColor(this.getTypeTagConfig(item.type)['bgColor'])
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    .borderRadius(4)
                    .margin({ right: 8 })

                  Text(item.title)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#333333')
                    .layoutWeight(1)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  // 人性化时间显示 (使用 sendTime)
                  Text(this.formatRelativeTime(item.sendTime)).fontSize(12).fontColor('#999999').margin({ left: 10 })
                }.width('100%').alignItems(VerticalAlign.Center)

                Text(item.content)
                  .fontSize(14)
                  .fontColor('#666666')
                  .margin({ top: 10 })
                  .lineHeight(20)
                  .width('100%')
              }
              .width('100%')
              .padding(15)
              .backgroundColor('#FFFFFF')
              .borderRadius(12)
              .shadow({ radius: 8, color: 'rgba(0,0,0,0.02)', offsetY: 2 })
            }
            .onClick(() => {
              // 如果这条消息关联了具体项目，点击可以直接跳转到项目详情！
              if (item.projectId) {
                // 修复 ArkTS 严格模式报错：显式声明路由参数的类型
                let routerParams: Record<string, number> = { 'id': item.projectId };
                router.pushUrl({
                  url: 'pages/ProjectDetail',
                  params: routerParams
                });
              }
            })
          }, (item: PushRecord) => item.id.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .padding(15)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA')
  }
}