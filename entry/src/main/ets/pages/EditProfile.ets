import router from '@ohos.router';
import HttpUtil, { BaseResponse } from '../utils/HttpUtil';
import picker from '@ohos.file.picker'; // 引入鸿蒙相册选择器
import fs from '@ohos.file.fs';
import request from '@ohos.request';
import { UIContext } from '@ohos.arkui.UIContext';
import promptAction from '@ohos.promptAction';

@CustomDialog
struct PasswordDialog { // 密码修改弹窗
  controller?: CustomDialogController
  @State oldPassword: string = ''
  @State newPassword: string = ''
  @State confirmPassword: string = ''
  @State isSubmitting: boolean = false

  // 接收父组件传进来的确认回调函数
  confirmAction?: (oldPwd: string, newPwd: string) => void

  build() {
    Column() {
      Text('修改密码').fontSize(18).fontWeight(FontWeight.Bold).margin({ bottom: 20 })

      TextInput({ placeholder: '请输入原密码' })
        .type(InputType.Password)
        .height(45).backgroundColor('#F5F7FA').borderRadius(8).margin({ bottom: 15 })
        .onChange((value: string) => { this.oldPassword = value })

      TextInput({ placeholder: '请输入新密码 (不少于6位)' })
        .type(InputType.Password)
        .height(45).backgroundColor('#F5F7FA').borderRadius(8).margin({ bottom: 15 })
        .onChange((value: string) => { this.newPassword = value })

      TextInput({ placeholder: '请再次输入新密码' })
        .type(InputType.Password)
        .height(45).backgroundColor('#F5F7FA').borderRadius(8).margin({ bottom: 20 })
        .onChange((value: string) => { this.confirmPassword = value })

      Row({ space: 15 }) {
        Button('取消')
          .backgroundColor('#EEEEEE').fontColor('#666666').layoutWeight(1)
          .onClick(() => { this.controller?.close() })

        Button(this.isSubmitting ? '提交中...' : '确认修改')
          .backgroundColor('#FF7E5F').fontColor('#FFFFFF').layoutWeight(1)
          .onClick(() => {
            if (this.newPassword.length < 6) {
              promptAction.showToast({ message: '新密码不能少于6位' })
              return
            }
            if (this.newPassword !== this.confirmPassword) {
              promptAction.showToast({ message: '两次输入的新密码不一致' })
              return
            }
            if (this.confirmAction) {
              this.isSubmitting = true
              this.confirmAction(this.oldPassword, this.newPassword)
            }
          })
      }.width('100%')
    }.padding(25).backgroundColor('#FFFFFF').borderRadius(16)
  }
}

@Entry
@Component
struct EditProfile {
  @StorageLink('nickname') currentNickname: string = '';
  @StorageLink('avatar') currentAvatar: string = ''; // 引入当前头像
  @StorageLink('userId') userId: number = 0;

  @State newNickname: string = '';
  // 临时存储准备上传/预览的本地或网络图片路径
  @State newAvatar: string = '';
  @State isSubmitting: boolean = false;

  pwdDialogController: CustomDialogController = new CustomDialogController({
    builder: PasswordDialog({
      confirmAction: (oldPwd, newPwd) => { this.handleUpdatePassword(oldPwd, newPwd) }
    }),
    customStyle: true, // 允许弹窗圆角等自定义样式生效
    alignment: DialogAlignment.Center
  })

  async handleUpdatePassword(oldPwd: string, newPwd: string) {
    let safeContext = this.getUIContext()
    try {
      let payload: Record<string, string> = {
        'oldPassword': oldPwd,
        'newPassword': newPwd
      };
      let res: BaseResponse = await HttpUtil.put(`/users/${this.userId}/password`, payload);

      if (Number(res.code) === 200) {
        safeContext.getPromptAction().showToast({ message: '密码修改成功，请重新登录' })
        this.pwdDialogController.close()

        // 延迟退出登录，彻底清空本地缓存
        setTimeout(() => {
          AppStorage.SetOrCreate('token', '');
          AppStorage.SetOrCreate('phone', '');
          AppStorage.SetOrCreate('nickname', '');
          AppStorage.SetOrCreate('userId', 0);
          AppStorage.SetOrCreate('avatar', '');
          AppStorage.SetOrCreate('isLoggedIn', false);

          // 跳转回登录页，并且清空路由栈，防止按返回键又回到这里
          router.clear()
          router.replaceUrl({ url: 'pages/Login' })
        }, 1500)
      } else {
        safeContext.getPromptAction().showToast({ message: res.msg || '密码修改失败' })
        // 恢复按钮状态
        this.pwdDialogController.close()
      }
    } catch (e) {
      safeContext.getPromptAction().showToast({ message: '请求失败，请检查网络' })
      this.pwdDialogController.close()
    }
  }

  aboutToAppear() {
    this.newNickname = this.currentNickname;
    this.newAvatar = this.currentAvatar;
  }

  // 唤起系统相册选图
  async selectAndUploadAvatar() {
    // 在执行任何 await 之前，存 UI 上下文
    let safeContext = this.getUIContext();

    try {
      let photoPicker = new picker.PhotoViewPicker();
      let selectOptions = new picker.PhotoSelectOptions();
      selectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
      selectOptions.maxSelectNumber = 1;

      // 这里一旦 await，就会切到后台
      let res = await photoPicker.select(selectOptions);

      if (res.photoUris && res.photoUris.length > 0) {
        let localUri = res.photoUris[0];
        this.newAvatar = localUri;

        // 使用提前保存好的 safeContext 弹窗
        safeContext.getPromptAction().showToast({ message: '图片上传中...' });

        // 把安全上下文传给上传函数
        await this.uploadImageToServer(localUri, safeContext);
      }
    } catch (e) {
      console.error('选择图片失败: ' + JSON.stringify(e));
    }
  }

  // 真实上传到服务器的逻辑
  async uploadImageToServer(localUri: string, safeContext: UIContext) {
    try {
      let context = getContext(this);
      let cacheDir = context.cacheDir;
      let tempFileName = `avatar_${Date.now()}.jpg`;
      let tempFilePath = `${cacheDir}/${tempFileName}`;

      let file = fs.openSync(localUri, fs.OpenMode.READ_ONLY);
      fs.copyFileSync(file.fd, tempFilePath);
      fs.closeSync(file);

      console.info(`[上传] 文件已拷贝至沙箱: internal://cache/${tempFileName}`);

      let token = AppStorage.Get<string>('token') || '';
      let uploadConfig: request.UploadConfig = {
        url: 'http://127.0.0.1:8080/api/v1/upload/avatar', // 后端地址
        header: {
          'Content-Type': 'multipart/form-data',
          'Authorization': token
        },
        method: 'POST',
        files: [{ filename: tempFileName, name: 'file', uri: `internal://cache/${tempFileName}`, type: 'jpg' }],
        data: []
      };

      let uploadTask = await request.uploadFile(context, uploadConfig);

      // 5. 监听响应头
      uploadTask.on('headerReceive', (header: object) => {
        let headers = header as Record<string, string>;
        console.info('[上传] 收到服务器响应头: ' + JSON.stringify(headers));

        if (headers['body']) {
          let resBody = JSON.parse(headers['body']) as Record<string, Object>;

          if (Number(resBody['code']) === 200 && resBody['data']) {
            this.newAvatar = String(resBody['data']);
            console.info('[上传] 成功获取网络路径: ' + this.newAvatar);
            // 使用传入的 safeContext 进行弹窗
            safeContext.getPromptAction().showToast({ message: '图片上传成功' });
          } else {
            safeContext.getPromptAction().showToast({ message: '服务器处理图片失败' });
          }
        }
      });

      uploadTask.on('fail', () => {
        console.error('[上传] 任务失败');
        safeContext.getPromptAction().showToast({ message: '网络不好，图片上传失败' });
      });

    } catch (error) {
      console.error("[上传] 异常: " + JSON.stringify(error));
      safeContext.getPromptAction().showToast({ message: '文件处理异常' });
    }
  }

  async handleUpdate() {
    if (!this.newNickname.trim()) {
      this.getUIContext().getPromptAction().showToast({ message: '昵称不能为空' });
      return;
    }

    this.isSubmitting = true;

    try {
      // Payload 里带上新的 avatar
      let payload: Record<string, string> = {
        'nickname': this.newNickname,
        'avatar': this.newAvatar
      };

      let res: BaseResponse = await HttpUtil.put(`/users/${this.userId}`, payload);

      if (Number(res.code) === 200) {
        this.getUIContext().getPromptAction().showToast({ message: '资料修改成功' });

        // 同步更新全局变量
        AppStorage.SetOrCreate('nickname', this.newNickname);
        AppStorage.SetOrCreate('avatar', this.newAvatar);

        setTimeout(() => { router.back(); }, 1000);
      } else {
        this.getUIContext().getPromptAction().showToast({ message: res.msg || '修改失败' });
      }
    } catch (e) {
      this.getUIContext().getPromptAction().showToast({ message: '网络请求异常' });
    } finally {
      this.isSubmitting = false;
    }
  }

  build() {
    Column() {
      // 导航栏
      Row() {
        Image('https://api.iconify.design/solar:alt-arrow-left-linear.svg?color=%23333333')
          .width(32).height(32).onClick(() => { router.back() })
        Text('修改个人资料').fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 15 })
      }.width('100%').padding(20)

      // 头像上传区域
      Column() {
        // 判断是本地相册URI还是网络路径
        Image(this.newAvatar.startsWith('file://') ? this.newAvatar : (this.newAvatar ? `http://192.168.59.47:8080${this.newAvatar}` : $r('app.media.startIcon')))
          .width(90).height(90).borderRadius(45)
          .objectFit(ImageFit.Cover)
          .border({ width: 3, color: '#FFF0E6' })

        Row() {
          Image('https://api.iconify.design/solar:camera-add-bold.svg?color=%23FFFFFF').width(16).height(16).margin({ right: 4 })
          Text('更换头像').fontSize(12).fontColor('#FFFFFF')
        }
        .backgroundColor('#FF7E5F').padding({ left: 10, right: 10, top: 4, bottom: 4 })
        .borderRadius(12).margin({ top: -15 }).zIndex(2)
      }
      .margin({ top: 10, bottom: 30 })
      .onClick(() => {
        this.selectAndUploadAvatar(); // 点击触发选图
      })

      // 表单区域
      Column() {
        Text('我的昵称').fontSize(14).fontColor('#666666').width('100%').margin({ bottom: 10, left: 10 })
        TextInput({ text: this.newNickname, placeholder: '请输入新昵称' })
          .height(50).backgroundColor('#FFFFFF').borderRadius(10)
          .onChange((value: string) => { this.newNickname = value; })

        Button(this.isSubmitting ? '保存中...' : '保存修改')
          .width('100%').height(50).backgroundColor('#FF7E5F').fontColor('#FFFFFF')
          .fontSize(16).fontWeight(FontWeight.Bold).margin({ top: 40 })
          .onClick(() => { this.handleUpdate(); })
        Button('修改密码')
          .width('100%').height(50).backgroundColor('#FF7E5F').fontColor('#FFFFFF')
          .fontSize(16).fontWeight(FontWeight.Bold).margin({ top: 15 })
          .onClick(() => {
            this.pwdDialogController.open()
          })
      }.width('92%')
    }
    .width('100%').height('100%').backgroundColor('#F7F8FA')
  }
}