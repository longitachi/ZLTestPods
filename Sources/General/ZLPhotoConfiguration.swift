//
//  ZLPhotoConfiguration.swift
//  ZLPhotoBrowser
//
//  Created by long on 2020/8/11.
//

import UIKit

public typealias Second = Int

public class ZLPhotoConfiguration: NSObject {

    private static let single = ZLPhotoConfiguration()
    
    @objc public class func `default`() -> ZLPhotoConfiguration {
        return ZLPhotoConfiguration.single
    }
    
    @objc public var statusBarStyle: UIStatusBarStyle = .lightContent
    
    /// 是否升序排列，预览界面不受该参数影响
    @objc public var sortAscending = true
    
    private var pri_maxSelectCount = 9
    @objc public var maxSelectCount: Int {
        set {
            pri_maxSelectCount = max(1, newValue)
        }
        get {
            return pri_maxSelectCount
        }
    }
    
    /// 混合选择时，照片和视频是否可以同时选择，默认true
    /// e.g. 希望选择视频（最多1个）后不能选择其他图片，或者选择图片（最多9张）后不能选择视频
    /// 设置如下参数即可
    /// allowSelectImage = true
    /// allowSelectVideo = true
    /// maxSelectCount = 9
    /// allowMixSelect = false
    @objc public var allowMixSelect = true
    
    /// 预览图最大显示数，该值为0时将不显示上方预览图，仅显示 '拍照、相册、取消' 按钮
    @objc public var maxPreviewCount = 20
    
    /// cell的圆角弧度
    @objc public var cellCornerRadio: CGFloat = 0
    
    @objc public var allowSelectImage = true
    
    @objc public var allowSelectVideo = true
    
    /// 是否允许选择Gif，只是控制是否选择，并不控制是否显示，如果为NO，则不显示gif标识
    @objc public var allowSelectGif = true
    
    /// 是否允许选择livePhoto，只是控制是否选择，并不控制是否显示，如果为NO，则不显示livePhoto标识
    @objc public var allowSelectLivePhoto = false
    
    /// 是否允许相册内部拍照
    @objc public var allowTakePhotoInLibrary = true
    
    /// 是否允许编辑图片，图片可允许编辑多张
    @objc public var allowEditImage = true
    
    /// 是否允许编辑视频
    /// - warning: 视频只能在没有选择任何照片的情况下，或仅选择一个视频的情况下编辑，编辑完成后立即执行选择回调
    @objc public var allowEditVideo = false
    
    /// 是否允许滑动选择
    @objc public var allowSlideSelect = true
    
    /// 预览界面是否允许拖拽选择
    @objc public var allowDragSelect = false
    
    /// 是否允许选择原图
    @objc public var allowSelectOriginal = true
    
    private var pri_maxEditVideoTime: Second = 10
    
    /// 编辑视频时最大裁剪时间，单位：秒，默认10s 且最小5s
    /// - discussion: 当该参数为10s时，所选视频时长必须大于等于10s才允许进行编辑
    @objc public var maxEditVideoTime: Second {
        set {
            pri_maxEditVideoTime = max(5, newValue)
        }
        get {
            return pri_maxEditVideoTime
        }
    }
    
    /// 允许选择视频的最大时长
    @objc public var maxSelectVideoDuration: Second = 120
    
    /// 允许选择视频的最小时长
    @objc public var minSelectVideoDuration: Second = 0
    
    /// 编辑图片工具，默认 涂鸦及裁剪（因swift OptionSet 不支持 @objc 标识，所以该属性oc不可用）
    public var editImageTools: ZLEditImageViewController.EditImageTool = [.draw, .clip]
    
    /// 编辑图片涂鸦颜色
    @objc public var editImageDrawColors: [UIColor] = [.white, .black, zlRGB(241, 79, 79), zlRGB(243, 170, 78), zlRGB(80, 169, 56), zlRGB(30, 183, 243), zlRGB(139, 105, 234)]
    
    /// 编辑图片涂鸦默认颜色
    @objc public var editImageDefaultDrawColor = zlRGB(241, 79, 79)
    
    /// 在小图界面选择 图片/视频 后直接进入编辑界面
    /// - discussion: 编辑图片 仅在allowEditImage为YES 且 maxSelectCount为1 的情况下，置为YES有效，
    /// 编辑视频则在 allowEditVideo为YES 且 maxSelectCount为1情况下，置为YES有效
    @objc public var editAfterSelectThumbnailImage = false
    
    /// 编辑图片后是否保存编辑后的图片至相册
    @objc public var saveNewImageAfterEdit = true
    
    /// 是否在相册内部拍照按钮上面实时显示相机俘获的影像
    @objc public var showCaptureImageOnTakePhotoBtn = false
    
    /// 控制单选模式下，是否显示选择按钮，多选模式不受控制
    @objc public var showSelectBtnWhenSingleSelect = false
    
    /// 是否在已选择的图片上方覆盖一层已选中遮罩层
    @objc public var showSelectedMask = true
    
    /// 遮罩层颜色
    @objc public var selectedMaskColor = UIColor.black.withAlphaComponent(0.2)
    
    /// 是否在不能选择的cell上方覆盖一层遮罩层
    @objc public var showInvalidMask = true
    
    /// 不能选择的cell上方遮罩层颜色
    @objc public var invalidMaskColor = UIColor.white.withAlphaComponent(0.5)
    
    /// 是否显示选中图片的index
    @objc public var showSelectedIndex = true
    
    /// 选中图片右上角index background color
    @objc public var indexLabelBgColor = zlRGB(80, 169, 56)
    
    /// 长按拍照按钮进行录像时的progress color
    @objc public var cameraProgressColor = zlRGB(80, 169, 56)
    
    /// 是否在预览界面下方显示已选择的照片
    @objc public var showSelectedPhotoPreview = true
    
    /// 支持开发者自定义图片，但是所自定义图片资源名称必须与被替换的bundle中的图片名称一致
    /// - example: 开发者需要替换选中与未选中的图片资源，则需要传入的数组为
    /// ["zl_btn_selected", "zl_btn_unselected"]，
    /// 则框架内会使用开发者项目中的图片资源，而其他图片则用框架bundle中的资源
    @objc public var customImageNames: [String] = [] {
        didSet {
            ZLCustomImageDeply.deploy = self.customImageNames
        }
    }
    
    /// 回调时候是否允许框架解析图片，默认YES
    /// discussion 如果选择了大量图片，框架一下解析大量图片会耗费一些内存，
    /// 开发者此时可置为NO，拿到assets数组后使用 ZLPhotoManager 中提供的 "anialysisAssets:original:completion:" 方法进行逐个解析，
    /// 以达到缓解内存瞬间暴涨的效果，该值为NO时，回调的图片数组为nil
    @objc public var shouldAnialysisAsset = true
    
    /// 解析图片超时时间
    @objc public var timeout: TimeInterval = 20
    
    /// 框架语言
    @objc public var languageType: ZLLanguageType = .system {
        didSet {
            ZLCustomLanguageDeploy.language = self.languageType
            Bundle.resetLanguage()
        }
    }
    
    /// 支持开发者自定义多语言提示，但是所自定义多语言的key必须与原key一致
    /// - example: 开发者需要替换
    /// key: "ZLPhotoBrowserLoadingText"，value:"正在处理..." 的多语言
    /// 则需要传入的字典为 ["ZLPhotoBrowserLoadingText": "需要替换的文字"]
    /// 而其他多语言则用框架中的
    /// - warning: 更改时请注意多语言中包含的占位符，如%ld、%@
    @objc public var customLanguageKeyValue: [String: String] = [:] {
        didSet {
            ZLCustomLanguageDeploy.deploy = self.customLanguageKeyValue
        }
    }
    
    /// 使用自定义相机相机
    @objc public var useCustomCamera = true
    
    /// 是否允许录制视频
    @objc public var allowRecordVideo = true
    
    private var pri_maxRecordDuration: Second = 10
    
    /// 最大录制时长，默认 10s，最小为 1s
    @objc public var maxRecordDuration: Second {
        set {
            pri_maxRecordDuration = max(1, newValue)
        }
        get {
            return pri_maxRecordDuration
        }
    }
    
    /// 视频分辨率
    @objc public var sessionPreset: ZLCustomCamera.CaptureSessionPreset = .hd1280x720
    
    /// 录制视频及编辑视频时候的视频导出格式
    @objc public var videoExportType: ZLCustomCamera.VideoExportType = .mov
    
    /// 闪光灯设置
    @objc public var cameraFlashMode: ZLCustomCamera.CameraFlashMode = .off
    
    /// hud style
    @objc public var hudStyle: ZLProgressHUD.HUDStyle = .lightBlur
    
    /// 下方工具条模糊样式
    @objc public var bottomToolViewBlurEffect: UIBlurEffect? = UIBlurEffect(style: .dark)
    
    /// 框架主题颜色配置
    @objc public var themeColorDeploy: ZLPhotoThemeColorDeploy = .default()
    
    /// 框架字体
    @objc public var themeFontName: String? = nil {
        didSet {
            ZLCustomFontDeploy.fontName = self.themeFontName
        }
    }
    
}


/// 框架内主题颜色配置
public class ZLPhotoThemeColorDeploy: NSObject {
    
    @objc public class func `default`() -> ZLPhotoThemeColorDeploy {
        return ZLPhotoThemeColorDeploy()
    }
    
    /// 导航条颜色
    @objc public var navBarColor = zlRGB(44, 45, 46)
    
    /// 导航标题颜色
    @objc public var navTitleColor = UIColor.white
    
    /// 预览选择模式下 上方透明背景色
    @objc public var previewBgColor = UIColor.black.withAlphaComponent(0.1)
    
    /// 预览选择模式下 拍照/相册/取消 的背景颜色
    @objc public var previewBtnBgColor = UIColor.white
    
    /// 预览选择模式下 拍照/相册/取消 的字体颜色
    @objc public var previewBtnTitleColor = UIColor.black
    
    /// 预览选择模式下 选择照片大于0时，取消按钮title颜色
    @objc public var previewBtnHighlightTitleColor = zlRGB(80, 169, 56)
    
    /// 相册列表界面背景色
    @objc public var albumListBgColor = UIColor.white
    
    /// 相册列表界面 相册title颜色
    @objc public var albumListTitleColor = UIColor.black
    
    /// 相册列表界面 数量label颜色
    @objc public var albumListCountColor = zlRGB(180, 180, 180)
    
    /// 分割线颜色
    @objc public var separatorColor = zlRGB(200, 200, 200)
    
    /// 小图界面背景色
    @objc public var thumbnailBgColor = zlRGB(50, 50, 50)
    
    /// 底部工具条底色
    @objc public var bottomToolViewBgColor = zlRGB(35, 35, 35).withAlphaComponent(0.1)
    
    /// 底部工具栏按钮 可交互 状态标题颜色
    @objc public var bottomToolViewBtnNormalTitleColor = UIColor.white
    
    /// 底部工具栏按钮 不可交互 状态标题颜色
    @objc public var bottomToolViewBtnDisableTitleColor = zlRGB(168, 168, 168)
    
    /// 底部工具栏按钮 可交互 状态背景颜色
    @objc public var bottomToolViewBtnNormalBgColor = zlRGB(80, 169, 56)
    
    /// 底部工具栏按钮 不可交互 状态背景颜色
    @objc public var bottomToolViewBtnDisableBgColor = zlRGB(50, 50, 50)
    
    /// 自定义相机录制视频时，进度条颜色
    @objc public var cameraRecodeProgressColor = zlRGB(80, 169, 56)
    
}


/// 框架字体配置
struct ZLCustomFontDeploy {
    
    static var fontName: String? = nil
    
}


/// 框架语言配置
struct ZLCustomLanguageDeploy {
    
    static var language: ZLLanguageType = .system
    
    static var deploy: [String: String] = [:]
    
}


/// 自定义图片配置
struct ZLCustomImageDeply {
    
    static var deploy: [String] = []
    
}
