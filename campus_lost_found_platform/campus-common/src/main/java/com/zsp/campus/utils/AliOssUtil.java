package com.zsp.campus.utils;

import com.aliyun.oss.ClientException;
import com.aliyun.oss.OSS;
import com.aliyun.oss.OSSClientBuilder;
import com.aliyun.oss.OSSException;
import com.aliyun.oss.model.GeneratePresignedUrlRequest;
import com.aliyun.oss.HttpMethod;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import java.io.ByteArrayInputStream;
import java.net.URL;
import java.util.Date;

@Data
@AllArgsConstructor
@Slf4j
public class AliOssUtil {

    private String endpoint;
    private String accessKeyId;
    private String accessKeySecret;
    private String bucketName;

    /** 签名URL默认有效期：1小时 */
    private static final long DEFAULT_EXPIRATION = 3600 * 1000L;

    /**
     * 图片文件上传，返回原始URL（不带签名）。
     * 数据库应存储此原始URL，返回前端时再通过 signUrl 动态生成签名URL。
     *
     * @param bytes      文件字节
     * @param objectName 对象名（含路径前缀，如 images/xxx.jpg）
     * @return 原始URL，格式 https://{bucket}.{endpoint}/{objectName}
     */
    public String upload(byte[] bytes, String objectName) {

        // 创建OSSClient实例。
        OSS ossClient = new OSSClientBuilder().build(endpoint, accessKeyId, accessKeySecret);

        try {
            // 创建PutObject请求。
            ossClient.putObject(bucketName, objectName, new ByteArrayInputStream(bytes));
            log.info("文件上传成功，objectName={}", objectName);
        } catch (OSSException oe) {
            System.out.println("Caught an OSSException, which means your request made it to OSS, "
                    + "but was rejected with an error response for some reason.");
            System.out.println("Error Message:" + oe.getErrorMessage());
            System.out.println("Error Code:" + oe.getErrorCode());
            System.out.println("Request ID:" + oe.getRequestId());
            System.out.println("Host ID:" + oe.getHostId());
        } catch (ClientException ce) {
            System.out.println("Caught an ClientException, which means the client encountered "
                    + "a serious internal problem while trying to communicate with OSS, "
                    + "such as not being able to access the network.");
            System.out.println("Error Message:" + ce.getMessage());
        } finally {
            if (ossClient != null) {
                ossClient.shutdown();
            }
        }

        // 返回原始URL（不带签名），存入数据库
        String url = "https://" + bucketName + "." + endpoint + "/" + objectName;
        log.info("文件上传到:{}", url);
        return url;
    }

    /**
     * 根据 objectName 生成带签名的临时访问URL。
     * 签名URL有时效性，每次访问前都应重新生成。
     *
     * @param objectName 对象名
     * @return 签名URL
     */
    public String generateSignedUrl(String objectName) {
        if (objectName == null || objectName.isEmpty()) {
            return objectName;
        }

        OSS ossClient = new OSSClientBuilder().build(endpoint, accessKeyId, accessKeySecret);
        try {
            Date expiration = new Date(new Date().getTime() + DEFAULT_EXPIRATION);
            GeneratePresignedUrlRequest request =
                    new GeneratePresignedUrlRequest(bucketName, objectName, HttpMethod.GET);
            request.setExpiration(expiration);
            URL signedUrl = ossClient.generatePresignedUrl(request);
            return signedUrl.toString();
        } catch (Exception e) {
            log.error("生成签名URL失败，objectName={}", objectName, e);
            return "https://" + bucketName + "." + endpoint + "/" + objectName;
        } finally {
            if (ossClient != null) {
                ossClient.shutdown();
            }
        }
    }

    /**
     * 将完整的OSS原始URL转换为签名URL。
     * 如果传入的不是本Bucket的URL（为空或不匹配），则原样返回。
     *
     * @param url 原始URL，格式 https://{bucket}.{endpoint}/{objectName}
     * @return 签名URL
     */
    public String signUrl(String url) {
        if (url == null || url.isEmpty()) {
            return url;
        }
        String prefix = "https://" + bucketName + "." + endpoint + "/";
        if (!url.startsWith(prefix)) {
            return url;
        }
        String objectName = url.substring(prefix.length());
        return generateSignedUrl(objectName);
    }
}