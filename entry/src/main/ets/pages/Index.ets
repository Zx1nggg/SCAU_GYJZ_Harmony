import { HomeView } from '../views/HomeView';
import { NotificationView } from '../views/NotificationView';
import { MineView } from '../views/MineView';

@Entry
@Component
struct Index {
  @State currentIndex: number = 0;
  private tabsController: TabsController = new TabsController();

  // 使用在线的 SVG 矢量图
  // [未选中状态线稿, 选中状态填充]
  private icons: Record<string, string[]> = {
    'home': [
      'https://api.iconify.design/solar:home-smile-linear.svg?color=%23999999',
      'https://api.iconify.design/solar:home-smile-bold.svg?color=%23FF7E5F'
    ],
    'notice': [
      'https://api.iconify.design/solar:bell-linear.svg?color=%23999999',
      'https://api.iconify.design/solar:bell-bold.svg?color=%23FF7E5F'
    ],
    'mine': [
      'https://api.iconify.design/solar:user-linear.svg?color=%23999999',
      'https://api.iconify.design/solar:user-bold.svg?color=%23FF7E5F'
    ]
  };

  @Builder TabBuilder(title: string, targetIndex: number, iconKey: string) {
    Column() {
      // 根据状态切换图标，并加入微小的缩放动画效果
      Image(this.currentIndex === targetIndex ? this.icons[iconKey][1] : this.icons[iconKey][0])
        .width(26)
        .height(26)
        .margin({ bottom: 4 })
        .animation({ duration: 200 })

      Text(title)
        .fontSize(11)
        .fontColor(this.currentIndex === targetIndex ? '#FF7E5F' : '#999999')
        .fontWeight(this.currentIndex === targetIndex ? FontWeight.Medium : FontWeight.Normal)
    }
    .width('100%')
    .height(50)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.currentIndex = targetIndex;
      this.tabsController.changeIndex(targetIndex);
    })
  }

  build() {
    Tabs({ barPosition: BarPosition.End, controller: this.tabsController }) {
      TabContent() {
        HomeView()
      }.tabBar(this.TabBuilder('首页', 0, 'home'))

      TabContent() {
        NotificationView()
      }.tabBar(this.TabBuilder('通知', 1, 'notice'))

      TabContent() {
        MineView()
      }.tabBar(this.TabBuilder('我的', 2, 'mine'))
    }
    .scrollable(false)
    .onChange((index: number) => {
      this.currentIndex = index;
    })
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA')
  }
}