import http from '@ohos.net.http';
import router from '@ohos.router';

const BASE_URL: string = "http://192.168.59.89:8080/api/v1"; // 换成本地的局域网IP

// 1. 明确定义后端返回的数据结构
export interface BaseResponse {
  code: number;
  msg?: string;
  data?: Object | null;
  records?: Object[];
  total?: number;
}

export default class HttpUtil {
  // 2. 明确参数类型为 Object，明确返回类型为 Promise<BaseResponse>
  static async request(url: string, method: http.RequestMethod, data?: Object): Promise<BaseResponse> {
    let httpRequest = http.createHttp();

    // 获取本地持久化的 Token
    let token: string = AppStorage.Get<string>('token') || '';

    let options: http.HttpRequestOptions = {
      method: method,
      header: {
        'Content-Type': 'application/json',
        'Authorization': token ? `Bearer ${token}` : ''
      },
      extraData: data,
      readTimeout: 10000,
      connectTimeout: 10000
    };

    try {
      let response = await httpRequest.request(BASE_URL + url, options);
      if (response.responseCode === 200) {
        // 将 JSON 字符串强制转换为我们定义的 BaseResponse 接口
        let resData = JSON.parse(response.result as string) as BaseResponse;

        if (resData.code === 401) {
          // Token 过期，跳转登录
          router.replaceUrl({ url: 'pages/Login' });
          return Promise.reject(new Error("未授权"));
        }
        return resData;
      } else {
        return Promise.reject(new Error("网络错误"));
      }
    } catch (err) {
      return Promise.reject(err as Error);
    }
  }

  // 3. 对于 URL 参数，使用 Record 泛型定义，防止 any 报错
  static get(url: string, params?: Record<string, string | number | boolean>): Promise<BaseResponse> {
    let query: string = '';
    if (params) {
      query = '?' + Object.keys(params).map(k => `${k}=${params[k]}`).join('&');
    }
    // 4. 将 this.request 改为类名 HttpUtil.request，解决 arkts-no-standalone-this 报错
    return HttpUtil.request(url + query, http.RequestMethod.GET);
  }

  static post(url: string, data?: Object): Promise<BaseResponse> {
    // 同理，使用类名调用
    return HttpUtil.request(url, http.RequestMethod.POST, data);
  }

  static put(url: string, data?: Object): Promise<BaseResponse> {
    return HttpUtil.request(url, http.RequestMethod.PUT, data);
  }

  static delete(url: string, params?: Record<string, string | number | boolean>): Promise<BaseResponse> {
    let query: string = '';
    if (params) {
      query = '?' + Object.keys(params).map(k => `${k}=${params[k]}`).join('&');
    }
    return HttpUtil.request(url + query, http.RequestMethod.DELETE);
  }
}