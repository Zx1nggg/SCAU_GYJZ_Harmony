import HttpUtil, { BaseResponse } from '../utils/HttpUtil';
import router from '@ohos.router';

export interface Project {
  id: number;
  title: string;
  category: string;
  targetAmount: number;
  currentAmount: number;
  coverImage: string;
  projectStatus: number;
}

@Component
export struct HomeView {
  @State projects: Project[] = [];
  @State loading: boolean = false;

  // 搜索和分类的状态变量
  @State searchQuery: string = '';
  @State currentCategory: string = '';

  private defaultImage: string = 'https://cube.elemecdn.com/e/fd/0fc7d20532fdaf769a25683617711png.png';

  aboutToAppear() {
    this.loadProjects();
  }

  onPageShow(): void {
    this.loadProjects();
  }

  async loadProjects() {
    this.loading = true;
    try {
      let params: Record<string, string | number | boolean> = {
        'page': 1,
        'size': 20,
        'status': 1
      };

      // 使用 encodeURIComponent 对中文字符串进行 URL 编码
      // 避免后端 Tomcat 抛出 RFC 7230 / RFC 3986 的 Invalid character 异常
      if (this.currentCategory !== '') {
        params['category'] = encodeURIComponent(this.currentCategory);
      }
      if (this.searchQuery !== '') {
        params['title'] = encodeURIComponent(this.searchQuery);
      }

      let res: BaseResponse = await HttpUtil.get('/projects', params);

      if (res.code === 200 && res.data) {
        let dataObj = res.data as Record<string, Object>;
        if (dataObj['records']) {
          this.projects = dataObj['records'] as Project[];
        }
      } else {
        // 如果后端查询不到数据，清空当前列表
        this.projects = [];
      }
    } catch (e) {
      console.error("加载项目失败");
      this.projects = [];
    } finally {
      this.loading = false;
    }
  }

  isProjectFinished(item: Project): boolean {
    if (!item) return false;
    return item.projectStatus === 2 || item.currentAmount >= item.targetAmount;
  }

  // 分离 UI显示名称(uiTitle) 和 真实查库名称(dbCategory)！
  @Builder CategoryIcon(icon: string, uiTitle: string, dbCategory: string) {
    Column({ space: 6 }) {
      Text(icon).fontSize(26)
      Text(uiTitle)
        .fontSize(12)
        // 动态高亮逻辑改为判断 dbCategory
        .fontColor(this.currentCategory === dbCategory ? '#FF7E5F' : '#333333')
        .fontWeight(this.currentCategory === dbCategory ? FontWeight.Bold : FontWeight.Normal)
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
    .backgroundColor(this.currentCategory === dbCategory ? 'rgba(255,126,95,0.1)' : 'transparent')
    .borderRadius(12)
    .onClick(() => {
      // 切换逻辑：点击时将真实的查库名称赋给 currentCategory
      if (this.currentCategory === dbCategory) {
        this.currentCategory = '';
      } else {
        this.currentCategory = dbCategory;
      }
      this.loadProjects();
    })
  }

  build() {
    Column() {
      //  顶部标题栏
      Row() {
        Text('让爱心触手可及')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
      }
      .width('100%')
      .height(60)
      .padding({ left: 20 })
      .backgroundColor('#FFFFFF')
      .shadow({ radius: 10, color: 'rgba(255,126,95,0.05)', offsetY: 2 })
      .zIndex(1)

      // 外层包裹 Scroll 组件
      Scroll() {
        Column() {
          Search({ placeholder: '搜索公益项目名称...', value: this.searchQuery })
            .searchButton('搜索')
            .width('92%')
            .height(40)
            .margin({ top: 15, bottom: 5 })
            .backgroundColor('#F5F7FA')
            .onSubmit((value: string) => {
              this.searchQuery = value;
              this.loadProjects();
            })
            .onChange((value: string) => {
              this.searchQuery = value;
              if (value === '') {
                this.loadProjects();
              }
            })

          Swiper() {
            Image($r('app.media.banner1')).width('100%').height(140).borderRadius(12)
            Image($r('app.media.banner2')).width('100%').height(140).borderRadius(12)
            Image($r('app.media.banner3')).width('100%').height(140).borderRadius(12)
            Image($r('app.media.banner4')).width('100%').height(140).borderRadius(12)
          }
          .autoPlay(true)
          .interval(3000)
          .padding({ left: 15, right: 15, top: 10 })

          Grid() {
            GridItem() { this.CategoryIcon("📚", "教育助学", "教育助学") }
            GridItem() { this.CategoryIcon("🏥", "医疗救助", "医疗救助") }
            GridItem() { this.CategoryIcon("⛑️", "灾害救援", "灾害救援") }
            GridItem() { this.CategoryIcon("🌲", "环境保护", "环境保护") }
            GridItem() { this.CategoryIcon("🏘️", "社区发展", "社区发展") }
            GridItem() { this.CategoryIcon("🐾", "动物保护", "动物保护") }
          }
          .columnsTemplate('1fr 1fr 1fr')
          .rowsTemplate('1fr 1fr')
          .rowsGap(6)
          .height(130)
          .padding({ left: 15, right: 15, top: 10, bottom: 5 })

          //  项目列表区
          if (this.projects.length === 0 && !this.loading) {
            Column() {
              Image('https://api.iconify.design/solar:box-minimalistic-duotone.svg?color=%23CCCCCC').width(80).height(80)
              Text('该分类下暂无项目').fontColor('#999999').margin({ top: 15 })
            }
            .margin({ top: 50 })
            .height('100%')
          } else {
            Grid() {
              ForEach(this.projects, (item: Project) => {
                GridItem() {
                  Column() {
                    Stack({ alignContent: Alignment.TopEnd }) {
                      Image(item.coverImage ? `http://192.168.59.45:8080${item.coverImage}` : this.defaultImage)
                        .width('100%')
                        .height(110)
                        .objectFit(ImageFit.Cover)

                      if (this.isProjectFinished(item)) {
                        Row()
                          .width('100%')
                          .height('100%')
                          .backgroundColor('rgba(0,0,0,0.4)')

                        Text('已达标')
                          .fontSize(12)
                          .fontWeight(FontWeight.Bold)
                          .fontColor('#FFFFFF')
                          .backgroundColor('#CCCCCC')
                          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                          .borderRadius({ bottomLeft: 8 })
                      }
                    }
                    .width('100%')
                    .height(110)

                    Column() {
                      Text(item.title)
                        .fontSize(15)
                        .fontWeight(FontWeight.Medium)
                        .fontColor(this.isProjectFinished(item) ? '#999999' : '#333333')
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .width('100%')

                      Blank()

                      Column() {
                        Text(`目标 ¥${item.targetAmount}`)
                          .fontSize(12)
                          .fontColor('#999999')
                          .margin({ bottom: 4 })
                        Text(`已筹 ¥${item.currentAmount}`)
                          .fontSize(13)
                          .fontWeight(FontWeight.Bold)
                          .fontColor(this.isProjectFinished(item) ? '#999999' : '#FF7E5F')
                      }
                      .alignItems(HorizontalAlign.Start)
                      .width('100%')
                    }
                    .padding(12)
                    .height(80)
                    .alignItems(HorizontalAlign.Start)
                  }
                  .width('100%')
                  .backgroundColor('#FFFFFF')
                  .borderRadius(12)
                  .border({ width: 1, color: this.isProjectFinished(item) ? '#F5F5F5' : '#FFF0E6' })
                  .shadow({ radius: 8, color: this.isProjectFinished(item) ? 'rgba(0,0,0,0.05)' : 'rgba(255,126,95,0.1)', offsetY: 4 })
                  .clip(true)
                  .onClick(() => {
                    let routerParams: Record<string, number> = { 'id': item.id };
                    router.pushUrl({ url: 'pages/ProjectDetail', params: routerParams });
                  })
                }
              }, (item: Project) => item.id.toString())
            }
            .columnsTemplate('1fr 1fr')
            .columnsGap(12)
            .rowsGap(12)
            .padding({ left: 15, right: 15, top: 15, bottom: 15 })
            .width('100%')
            .height('100%')
            .nestedScroll({
              scrollForward: NestedScrollMode.PARENT_FIRST, // 向上滑时：父组件(外层Scroll)先滑，滑不动了子组件(Grid)再滑
              scrollBackward: NestedScrollMode.SELF_FIRST   // 向下滑时：子组件(Grid)先滑，滑到顶了父组件(外层Scroll)再滑
            })
          }
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off) // 隐藏外层滚动条
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FDFDFE')
  }
}