// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

#if os(macOS)
  import AppKit
#elseif os(iOS)
  import UIKit
#elseif os(tvOS) || os(watchOS)
  import UIKit
#endif

// Deprecated typealiases
@available(*, deprecated, renamed: "ColorAsset.Color", message: "This typealias will be removed in SwiftGen 7.0")
public typealias AssetColorTypeAlias = ColorAsset.Color
@available(*, deprecated, renamed: "ImageAsset.Image", message: "This typealias will be removed in SwiftGen 7.0")
public typealias AssetImageTypeAlias = ImageAsset.Image

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Asset Catalogs

// swiftlint:disable identifier_name line_length nesting type_body_length type_name
public enum Asset {
  public enum Colors {
    public static let cloud = ColorAsset(name: "Cloud")
    public static let lightRose = ColorAsset(name: "LightRose")
    public static let lightSea = ColorAsset(name: "LightSea")
    public static let lightSun = ColorAsset(name: "LightSun")
    public static let lime = ColorAsset(name: "Lime")
    public static let listSeparator = ColorAsset(name: "ListSeparator")
    public static let mint = ColorAsset(name: "Mint")
    public static let mountain = ColorAsset(name: "Mountain")
    public static let night = ColorAsset(name: "Night")
    public static let rain = ColorAsset(name: "Rain")
    public static let rose = ColorAsset(name: "Rose")
    public static let searchBarBgColor = ColorAsset(name: "SearchBarBgColor")
    public static let silver = ColorAsset(name: "Silver")
    public static let sky = ColorAsset(name: "Sky")
    public static let smoke = ColorAsset(name: "Smoke")
    public static let snow = ColorAsset(name: "Snow")
    public static let sun = ColorAsset(name: "Sun")
    // swiftlint:disable trailing_comma
    public static let allColors: [ColorAsset] = [
      cloud,
      lightRose,
      lightSea,
      lightSun,
      lime,
      listSeparator,
      mint,
      mountain,
      night,
      rain,
      rose,
      searchBarBgColor,
      silver,
      sky,
      smoke,
      snow,
      sun,
    ]
    public static let allImages: [ImageAsset] = [
    ]
    // swiftlint:enable trailing_comma
  }
  public enum Icons {
    public static let copyFilled = ImageAsset(name: "copy-filled")
    public static let key = ImageAsset(name: "key")
    public static let past = ImageAsset(name: "past")
    public static let qr = ImageAsset(name: "qr")
    public static let remove = ImageAsset(name: "remove")
    public static let send = ImageAsset(name: "send")
    public static let warning = ImageAsset(name: "warning")
    // swiftlint:disable trailing_comma
    public static let allColors: [ColorAsset] = [
    ]
    public static let allImages: [ImageAsset] = [
      copyFilled,
      key,
      past,
      qr,
      remove,
      send,
      warning,
    ]
    // swiftlint:enable trailing_comma
  }
  public enum MaterialIcon {
    public static let accountBalanceWalletOutlined = ImageAsset(name: "account_balance_wallet_outlined")
    public static let add = ImageAsset(name: "add")
    public static let addBox = ImageAsset(name: "add_box")
    public static let addCircle = ImageAsset(name: "add_circle")
    public static let addCircleOutline = ImageAsset(name: "add_circle_outline")
    public static let appleLogo = ImageAsset(name: "apple_logo")
    public static let apps = ImageAsset(name: "apps")
    public static let archive = ImageAsset(name: "archive")
    public static let arrowBack = ImageAsset(name: "arrow_back")
    public static let arrowBackIos = ImageAsset(name: "arrow_back_ios")
    public static let arrowDownward = ImageAsset(name: "arrow_downward")
    public static let arrowDropDown = ImageAsset(name: "arrow_drop_down")
    public static let arrowDropDownCircle = ImageAsset(name: "arrow_drop_down_circle")
    public static let arrowDropUp = ImageAsset(name: "arrow_drop_up")
    public static let arrowForward = ImageAsset(name: "arrow_forward")
    public static let arrowForwardIos = ImageAsset(name: "arrow_forward_ios")
    public static let arrowLeft = ImageAsset(name: "arrow_left")
    public static let arrowRight = ImageAsset(name: "arrow_right")
    public static let arrowUpward = ImageAsset(name: "arrow_upward")
    public static let attribution = ImageAsset(name: "attribution")
    public static let backspace = ImageAsset(name: "backspace")
    public static let ballot = ImageAsset(name: "ballot")
    public static let block = ImageAsset(name: "block")
    public static let cancel = ImageAsset(name: "cancel")
    public static let check = ImageAsset(name: "check")
    public static let checkmark = ImageAsset(name: "checkmark")
    public static let chevronLeft = ImageAsset(name: "chevron_left")
    public static let chevronRight = ImageAsset(name: "chevron_right")
    public static let clear = ImageAsset(name: "clear")
    public static let close = ImageAsset(name: "close")
    public static let copy = ImageAsset(name: "copy")
    public static let create = ImageAsset(name: "create")
    public static let cut = ImageAsset(name: "cut")
    public static let deleteSweep = ImageAsset(name: "delete_sweep")
    public static let drafts = ImageAsset(name: "drafts")
    public static let expandLess = ImageAsset(name: "expand_less")
    public static let expandMore = ImageAsset(name: "expand_more")
    public static let fileCopy = ImageAsset(name: "file_copy")
    public static let filterList = ImageAsset(name: "filter_list")
    public static let firstPage = ImageAsset(name: "first_page")
    public static let flag = ImageAsset(name: "flag")
    public static let fontDownload = ImageAsset(name: "font_download")
    public static let forward = ImageAsset(name: "forward")
    public static let fullscreen = ImageAsset(name: "fullscreen")
    public static let fullscreenExit = ImageAsset(name: "fullscreen_exit")
    public static let gesture = ImageAsset(name: "gesture")
    public static let helpOutline = ImageAsset(name: "help_outline")
    public static let howToReg = ImageAsset(name: "how_to_reg")
    public static let howToVote = ImageAsset(name: "how_to_vote")
    public static let inbox = ImageAsset(name: "inbox")
    public static let lastPage = ImageAsset(name: "last_page")
    public static let link = ImageAsset(name: "link")
    public static let linkOff = ImageAsset(name: "link_off")
    public static let lowPriority = ImageAsset(name: "low_priority")
    public static let magnifyingGlass = ImageAsset(name: "magnifyingGlass")
    public static let mail = ImageAsset(name: "mail")
    public static let markunread = ImageAsset(name: "markunread")
    public static let menu = ImageAsset(name: "menu")
    public static let moreHoriz = ImageAsset(name: "more_horiz")
    public static let moreVert = ImageAsset(name: "more_vert")
    public static let moveToInbox = ImageAsset(name: "move_to_inbox")
    public static let newReleasesOutlined = ImageAsset(name: "new_releases_outlined")
    public static let nextWeek = ImageAsset(name: "next_week")
    public static let outlinedFlag = ImageAsset(name: "outlined_flag")
    public static let paste = ImageAsset(name: "paste")
    public static let redo = ImageAsset(name: "redo")
    public static let refresh = ImageAsset(name: "refresh")
    public static let remove = ImageAsset(name: "remove")
    public static let removeCircle = ImageAsset(name: "remove_circle")
    public static let removeCircleOutline = ImageAsset(name: "remove_circle_outline")
    public static let reply = ImageAsset(name: "reply")
    public static let replyAll = ImageAsset(name: "reply_all")
    public static let report = ImageAsset(name: "report")
    public static let reportGmailerrorred = ImageAsset(name: "report_gmailerrorred")
    public static let reportOff = ImageAsset(name: "report_off")
    public static let save = ImageAsset(name: "save")
    public static let saveAlt = ImageAsset(name: "save_alt")
    public static let selectAll = ImageAsset(name: "select_all")
    public static let send = ImageAsset(name: "send")
    public static let sort = ImageAsset(name: "sort")
    public static let a = ImageAsset(name: "a")
    public static let e = ImageAsset(name: "e")
    public static let k = ImageAsset(name: "k")
    public static let p1 = ImageAsset(name: "p1")
    public static let p2 = ImageAsset(name: "p2")
    public static let y = ImageAsset(name: "y")
    public static let subdirectoryArrowLeft = ImageAsset(name: "subdirectory_arrow_left")
    public static let subdirectoryArrowRight = ImageAsset(name: "subdirectory_arrow_right")
    public static let textFormat = ImageAsset(name: "text_format")
    public static let unarchive = ImageAsset(name: "unarchive")
    public static let undo = ImageAsset(name: "undo")
    public static let unfoldLess = ImageAsset(name: "unfold_less")
    public static let unfoldMore = ImageAsset(name: "unfold_more")
    public static let waves = ImageAsset(name: "waves")
    public static let weekend = ImageAsset(name: "weekend")
    public static let whereToVote = ImageAsset(name: "where_to_vote")
    // swiftlint:disable trailing_comma
    public static let allColors: [ColorAsset] = [
    ]
    public static let allImages: [ImageAsset] = [
      accountBalanceWalletOutlined,
      add,
      addBox,
      addCircle,
      addCircleOutline,
      appleLogo,
      apps,
      archive,
      arrowBack,
      arrowBackIos,
      arrowDownward,
      arrowDropDown,
      arrowDropDownCircle,
      arrowDropUp,
      arrowForward,
      arrowForwardIos,
      arrowLeft,
      arrowRight,
      arrowUpward,
      attribution,
      backspace,
      ballot,
      block,
      cancel,
      check,
      checkmark,
      chevronLeft,
      chevronRight,
      clear,
      close,
      copy,
      create,
      cut,
      deleteSweep,
      drafts,
      expandLess,
      expandMore,
      fileCopy,
      filterList,
      firstPage,
      flag,
      fontDownload,
      forward,
      fullscreen,
      fullscreenExit,
      gesture,
      helpOutline,
      howToReg,
      howToVote,
      inbox,
      lastPage,
      link,
      linkOff,
      lowPriority,
      magnifyingGlass,
      mail,
      markunread,
      menu,
      moreHoriz,
      moreVert,
      moveToInbox,
      newReleasesOutlined,
      nextWeek,
      outlinedFlag,
      paste,
      redo,
      refresh,
      remove,
      removeCircle,
      removeCircleOutline,
      reply,
      replyAll,
      report,
      reportGmailerrorred,
      reportOff,
      save,
      saveAlt,
      selectAll,
      send,
      sort,
      a,
      e,
      k,
      p1,
      p2,
      y,
      subdirectoryArrowLeft,
      subdirectoryArrowRight,
      textFormat,
      unarchive,
      undo,
      unfoldLess,
      unfoldMore,
      waves,
      weekend,
      whereToVote,
    ]
    // swiftlint:enable trailing_comma
  }
}
// swiftlint:enable identifier_name line_length nesting type_body_length type_name

// MARK: - Implementation Details

public final class ColorAsset {
  public fileprivate(set) var name: String

  #if os(macOS)
  public typealias Color = NSColor
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  public typealias Color = UIColor
  #endif

  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  public private(set) lazy var color: Color = {
    guard let color = Color(asset: self) else {
      fatalError("Unable to load color asset named \(name).")
    }
    return color
  }()

  #if os(iOS) || os(tvOS)
  @available(iOS 11.0, tvOS 11.0, *)
  public func color(compatibleWith traitCollection: UITraitCollection) -> Color {
    let bundle = BundleToken.bundle
    guard let color = Color(named: name, in: bundle, compatibleWith: traitCollection) else {
      fatalError("Unable to load color asset named \(name).")
    }
    return color
  }
  #endif

  fileprivate init(name: String) {
    self.name = name
  }
}

public extension ColorAsset.Color {
  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  convenience init?(asset: ColorAsset) {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSColor.Name(asset.name), bundle: bundle)
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

public struct ImageAsset {
  public fileprivate(set) var name: String

  #if os(macOS)
  public typealias Image = NSImage
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  public typealias Image = UIImage
  #endif

  @available(iOS 8.0, tvOS 9.0, watchOS 2.0, macOS 10.7, *)
  public var image: Image {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    let image = Image(named: name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    let name = NSImage.Name(self.name)
    let image = (bundle == .main) ? NSImage(named: name) : bundle.image(forResource: name)
    #elseif os(watchOS)
    let image = Image(named: name)
    #endif
    guard let result = image else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }

  #if os(iOS) || os(tvOS)
  @available(iOS 8.0, tvOS 9.0, *)
  public func image(compatibleWith traitCollection: UITraitCollection) -> Image {
    let bundle = BundleToken.bundle
    guard let result = Image(named: name, in: bundle, compatibleWith: traitCollection) else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }
  #endif
}

public extension ImageAsset.Image {
  @available(iOS 8.0, tvOS 9.0, watchOS 2.0, *)
  @available(macOS, deprecated,
    message: "This initializer is unsafe on macOS, please use the ImageAsset.image property")
  convenience init?(asset: ImageAsset) {
    #if os(iOS) || os(tvOS)
    let bundle = BundleToken.bundle
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSImage.Name(asset.name))
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
