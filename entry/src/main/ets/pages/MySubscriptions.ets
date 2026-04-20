import router from '@ohos.router';
import HttpUtil, { BaseResponse } from '../utils/HttpUtil';

// 严格对齐后端的 SubscriptionVO 实体类
export interface SubscriptionVO {
  id: number;
  projectId: number;
  projectTitle: string;
  projectStatus: number;
  createTime: string;
}

@Entry
@Component
struct MySubscriptions {
  @State records: SubscriptionVO[] = [];
  @State isLoading: boolean = true;
  @StorageLink('userId') userId: number = 0;

  // 记录搜索框的关键字
  @State searchQuery: string = '';

  aboutToAppear() {
    this.fetchSubscriptionList();
  }

  async fetchSubscriptionList() {
    if (!this.userId) {
      this.getUIContext().getPromptAction().showToast({ message: '用户未登录' });
      return;
    }

    try {
      this.isLoading = true;
      let res: BaseResponse = await HttpUtil.get(`/subscriptions/my?userId=${this.userId}`);

      if (Number(res.code) === 200 && res.data) {
        this.records = res.data as SubscriptionVO[];
      } else {
        this.getUIContext().getPromptAction().showToast({ message: res.msg || '获取订阅失败' });
      }
    } catch (e) {
      console.error('[MySubscriptions] 请求异常: ' + JSON.stringify(e));
      this.getUIContext().getPromptAction().showToast({ message: '网络请求异常' });
    } finally {
      this.isLoading = false;
    }
  }

  // 基于关键字过滤列表数据 (实时计算)
  getFilteredRecords(): SubscriptionVO[] {
    if (!this.searchQuery.trim()) {
      return this.records;
    }
    return this.records.filter((item) =>
    item.projectTitle && item.projectTitle.includes(this.searchQuery.trim())
    );
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Image('https://api.iconify.design/solar:alt-arrow-left-linear.svg?color=%23333333')
          .width(32).height(32)
          .onClick(() => { router.back() })
        Text('我订阅的项目').fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 15 })
      }.width('100%').padding({ left: 20, right: 20, top: 15, bottom: 10 }).justifyContent(FlexAlign.Start).backgroundColor('#F7F8FA')

      // 搜索栏
      Search({ placeholder: '搜索订阅项目名称...', value: this.searchQuery })
        .searchButton('搜索')
        .width('92%')
        .height(40)
        .margin({ bottom: 10 })
        .backgroundColor('#FFFFFF')
        .border({ width: 1, color: '#EEEEEE', radius: 20 })
        .onChange((value: string) => {
          // 只要输入框内容一变，自动触发重新渲染
          this.searchQuery = value;
        })

      // 列表区域
      if (this.isLoading) {
        LoadingProgress().width(50).height(50).margin({ top: 100 })
      } else if (this.records.length === 0) {
        Column() {
          Image('https://api.iconify.design/solar:star-fall-minimalistic-duotone.svg?color=%23CCCCCC')
            .width(80).height(80)
          Text('暂无订阅，快去探索感兴趣的项目吧').fontColor('#999999').margin({ top: 15 })
        }.margin({ top: 120 })
      } else if (this.getFilteredRecords().length === 0) {
        //  新增：当搜索不到结果时的提示
        Column() {
          Image('https://api.iconify.design/solar:magnifer-bug-duotone.svg?color=%23CCCCCC')
            .width(80).height(80)
          Text('没有找到匹配的项目').fontColor('#999999').margin({ top: 15 })
        }.margin({ top: 120 })
      } else {
        List({ space: 15 }) {
          // ForEach 绑定的不再是 this.records，而是 this.getFilteredRecords()
          ForEach(this.getFilteredRecords(), (item: SubscriptionVO) => {
            ListItem() {
              Row() {
                // 无图排版，使用质感徽章作为视觉锚点
                Stack() {
                  Circle({ width: 50, height: 50 })
                    .fill(item.projectStatus === 1 ? 'rgba(255, 126, 95, 0.1)' : '#F0F0F0')

                  Image(item.projectStatus === 1
                    ? 'https://api.iconify.design/solar:star-bold-duotone.svg?color=%23FF7E5F'
                    : 'https://api.iconify.design/solar:archive-minimalistic-bold-duotone.svg?color=%23999999')
                    .width(26).height(26)
                }.margin({ right: 15 })

                // 右侧信息架构
                Column() {
                  Text(item.projectTitle || '公益项目')
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(item.projectStatus === 1 ? '#333333' : '#888888') // 已结束稍微置灰
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')

                  Blank() // 将底部的标签和时间推到底部

                  Row() {
                    // 状态标签
                    Text(item.projectStatus === 1 ? '募集中' : '已结束')
                      .fontSize(11)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(item.projectStatus === 1 ? '#52C41A' : '#999999')
                      .backgroundColor(item.projectStatus === 1 ? '#F6FFED' : '#F5F5F5')
                      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                      .borderRadius(6)

                    Blank()

                    // 精致的时间组件
                    Row() {
                      Image('https://api.iconify.design/solar:clock-circle-linear.svg?color=%23999999')
                        .width(14).height(14).margin({ right: 4 })
                      Text((item.createTime || '').substring(0, 10))
                        .fontSize(12).fontColor('#999999')
                    }
                  }.width('100%').alignItems(VerticalAlign.Center)
                }
                .layoutWeight(1)
                .height(56) // 固定高度，保证徽章和文字对齐
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              .padding(20)
              .backgroundColor('#FFFFFF')
              .borderRadius(16) // 更大的圆角
              .shadow({ radius: 15, color: 'rgba(0,0,0,0.04)', offsetY: 5 }) // 更柔和的悬浮阴影
            }
            .onClick(() => {
              let routerParams: Record<string, number> = { 'id': item.projectId };
              router.pushUrl({ url: 'pages/ProjectDetail', params: routerParams });
            })
          }, (item: SubscriptionVO) => item.id.toString())
        }.width('92%').layoutWeight(1).margin({ top: 10 }).edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%').height('100%').backgroundColor('#F7F8FA')
  }
}