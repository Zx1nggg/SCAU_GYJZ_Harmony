import router from '@ohos.router';
import HttpUtil, { BaseResponse } from '../utils/HttpUtil';

export interface DonationRecordDTO {
  id: number;
  projectName: string;
  amount: number;
  donationTime: string;
  certificateNo: string;
}

@Entry
@Component
struct MyDonations {
  @State records: DonationRecordDTO[] = [];
  @State isLoading: boolean = true;
  // 搜索关键词状态
  @State searchQuery: string = '';

  @StorageLink('phone') phone: string = '';

  aboutToAppear() {
    this.fetchDonationList();
  }

  async fetchDonationList() {
    if (!this.phone) {
      this.getUIContext().getPromptAction().showToast({ message: '用户未登录' });
      return;
    }

    try {
      this.isLoading = true;
      let url = `/donations/my?phone=${this.phone}&page=1&size=100`; // 稍微调大size，方便本地检索
      let res: BaseResponse = await HttpUtil.get(url);

      if (Number(res.code) === 200 && res.data) {
        let pageData = res.data as Record<string, Object>;
        if (pageData['records']) {
          this.records = pageData['records'] as DonationRecordDTO[];
        } else if (Array.isArray(res.data)) {
          this.records = res.data as DonationRecordDTO[];
        }
      } else {
        this.getUIContext().getPromptAction().showToast({ message: res.msg || '获取列表失败' });
      }
    } catch (e) {
      this.getUIContext().getPromptAction().showToast({ message: '网络请求异常' });
    } finally {
      this.isLoading = false;
    }
  }

  // 新增：过滤后的列表数据获取方法
  getFilteredRecords(): DonationRecordDTO[] {
    if (!this.searchQuery) {
      return this.records;
    }
    // 忽略大小写的本地关键词过滤
    return this.records.filter(item =>
    (item.projectName || '').toLowerCase().includes(this.searchQuery.toLowerCase())
    );
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Image('https://api.iconify.design/solar:alt-arrow-left-linear.svg?color=%23333333')
          .width(32).height(32)
          .onClick(() => { router.back() })
        Text('我的捐赠记录').fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 15 })
      }.width('100%').padding(20).justifyContent(FlexAlign.Start).backgroundColor('#FFFFFF')

      // 新增：精美的搜索框
      Row() {
        Image('https://api.iconify.design/solar:magnifer-linear.svg?color=%23999999').width(20).height(20).margin({ right: 8 })
        TextInput({ placeholder: '搜索公益项目名称...', text: this.searchQuery })
          .layoutWeight(1)
          .height(40)
          .backgroundColor(Color.Transparent)
          .onChange((value: string) => {
            this.searchQuery = value; // 实时触发UI更新，秒搜！
          })
        if (this.searchQuery) {
          Image('https://api.iconify.design/solar:close-circle-bold.svg?color=%23CCCCCC')
            .width(20).height(20)
            .onClick(() => { this.searchQuery = ''; })
        }
      }
      .width('92%').height(46).backgroundColor('#FFFFFF').borderRadius(23)
      .padding({ left: 15, right: 15 }).margin({ top: 10, bottom: 10 })
      .shadow({ radius: 10, color: 'rgba(0,0,0,0.03)', offsetY: 2 })

      // 列表区域
      if (this.isLoading) {
        LoadingProgress().width(50).height(50).margin({ top: 100 })
      } else if (this.getFilteredRecords().length === 0) {
        Column() {
          Image('https://api.iconify.design/solar:box-minimalistic-duotone.svg?color=%23CCCCCC').width(80).height(80)
          Text(this.records.length === 0 ? '暂无捐赠记录，快去传递爱心吧' : '未找到相关项目').fontColor('#999999').margin({ top: 15 })
        }.margin({ top: 100 })
      } else {
        List({ space: 15 }) {
          // 修改点：使用过滤后的数组
          ForEach(this.getFilteredRecords(), (item: DonationRecordDTO) => {
            ListItem() {
              Column() {
                Row() {
                  Text(item.projectName || '公益项目').fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333333')
                  Text(`¥${item.amount}`).fontSize(18).fontWeight(FontWeight.Bold).fontColor('#FF7E5F')
                }.width('100%').justifyContent(FlexAlign.SpaceBetween)

                Row() {
                  Text(`证书编号: ${item.certificateNo || '处理中'}`).fontSize(12).fontColor('#999999')
                  Text((item.donationTime || '').substring(0, 10)).fontSize(12).fontColor('#999999')
                }.width('100%').justifyContent(FlexAlign.SpaceBetween).margin({ top: 10 })
              }
              .width('100%').padding(20).backgroundColor('#FFFFFF').borderRadius(12)
              .shadow({ radius: 10, color: 'rgba(0,0,0,0.02)', offsetY: 2 })
            }
          })
        }.width('92%').layoutWeight(1).edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%').height('100%').backgroundColor('#F7F8FA')
  }
}