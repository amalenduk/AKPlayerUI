//
//  AKMediaDetailsView.swift
//  AKPlayerUI
//

import SwiftUI
import AVFoundation
import AKPlayer

/// Pure content view displaying detailed technical and static metadata about the currently playing media item.
/// Renders resolution, duration, live stream vs local file status, file size on disk, audio/subtitle tracks, codecs, and content descriptors.
public struct AKMediaDetailsView: View {
    public var coordinator: AKPlayerCoordinator

    @Environment(\.akPlayerTheme) private var theme

    private var palette: AKColorPalette { theme.palette }
    private var typography: AKTypography { theme.typography }

    public init(coordinator: AKPlayerCoordinator = .shared) {
        self.coordinator = coordinator
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: AKSpacing.lg) {
                // 1. Header Media Summary Banner
                summaryBanner

                // 2. Playback & Stream Specifications
                streamSpecsSection

                // 3. Tracks & Capabilities
                tracksSection

                // 4. Source & Technical Attributes (Local File or Remote Stream)
                sourceTechnicalSection

                // 5. Extended Metadata (Description, Genre, Copyright, Publisher)
                if hasExtendedMetadata {
                    extendedMetadataSection
                }

                Spacer(minLength: AKSpacing.xxl)
            }
            .padding(.horizontal, AKSpacing.lg)
            .padding(.top, AKSpacing.md)
            .padding(.bottom, AKSpacing.xl)
        }
    }

    // MARK: - Summary Banner

    private var summaryBanner: some View {
        HStack(alignment: .center, spacing: AKSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(palette.accent.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: summaryIconName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(palette.accent)
            }

            VStack(alignment: .leading, spacing: AKSpacing.xxs) {
                Text(resolvedTitle)
                    .font(typography.headline)
                    .foregroundColor(palette.textPrimary)
                    .lineLimit(2)

                if !resolvedSubtitle.isEmpty {
                    Text(resolvedSubtitle)
                        .font(typography.subheadline)
                        .foregroundColor(palette.textSecondary)
                        .lineLimit(1)
                }

                HStack(spacing: AKSpacing.xs) {
                    if isLocalFile {
                        badgePill(text: "LOCAL FILE", color: palette.accent)
                    } else {
                        badgePill(
                            text: coordinator.isLive ? "LIVE STREAM" : "VOD",
                            color: coordinator.isLive ? Color.red : palette.accent
                        )
                    }

                    badgePill(
                        text: coordinator.isAudioOnly ? "AUDIO" : "VIDEO",
                        color: palette.textSecondary.opacity(0.8)
                    )

                    if let fileSize = localFileSizeString {
                        badgePill(text: fileSize, color: Color.green.opacity(0.9))
                    }

                    if let resolutionBadge = resolutionTag {
                        badgePill(text: resolutionBadge, color: palette.accent)
                    }
                }
                .padding(.top, AKSpacing.xxxs)
            }

            Spacer()
        }
        .padding(AKSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(palette.glassBorder, lineWidth: 1)
                )
        )
    }

    private var summaryIconName: String {
        if isLocalFile {
            return coordinator.isAudioOnly ? "music.note" : "internaldrive.fill"
        } else if coordinator.isLive {
            return "antenna.radiowaves.left.and.right"
        } else if coordinator.isAudioOnly {
            return "waveform"
        } else {
            return "film.fill"
        }
    }

    // MARK: - Stream Specifications Section

    private var streamSpecsSection: some View {
        infoCard(title: isLocalFile ? "Playback & Dimensions" : "Stream & Playback") {
            infoRow(
                icon: "clock.fill",
                label: "Duration",
                value: coordinator.isLive ? "Live Broadcast" : formatTime(coordinator.duration)
            )

            if !coordinator.isLive && coordinator.duration > 0 {
                infoRow(
                    icon: "play.circle.fill",
                    label: "Current Position",
                    value: "\(formatTime(coordinator.currentTime)) (\(progressPercentage)%)"
                )
            }

            if !coordinator.isAudioOnly {
                infoRow(
                    icon: "aspectratio.fill",
                    label: "Video Resolution",
                    value: resolutionString
                )

                infoRow(
                    icon: "viewfinder",
                    label: "Aspect Ratio",
                    value: aspectRatioString
                )
            }

            infoRow(
                icon: "speedometer",
                label: "Playback Rate",
                value: String(format: "%.2fx", coordinator.playbackRate)
            )
        }
    }

    // MARK: - Tracks Section

    private var tracksSection: some View {
        infoCard(title: "Tracks & Chapters") {
            infoRow(
                icon: "speaker.wave.2.fill",
                label: "Audio Track",
                value: coordinator.selectedAudioTrack?.title ?? (coordinator.availableAudioTracks.isEmpty ? "Default Audio" : "Automatic")
            )

            infoRow(
                icon: "captions.bubble.fill",
                label: "Subtitles",
                value: coordinator.selectedSubtitleTrack?.title ?? "Off"
            )

            infoRow(
                icon: "bookmark.fill",
                label: "Chapters",
                value: coordinator.chapters.isEmpty ? "None" : "\(coordinator.chapters.count) chapters"
            )
        }
    }

    // MARK: - Source & Technical Section (Local File vs Remote Stream)

    private var sourceTechnicalSection: some View {
        infoCard(title: isLocalFile ? "Local File Attributes" : "Source Attributes") {
            if let url = coordinator.currentMedia?.url {
                infoRow(
                    icon: isLocalFile ? "internaldrive.fill" : "globe",
                    label: "Source Type",
                    value: isLocalFile ? "Local Storage (On-Device)" : "Remote Network Stream"
                )

                if isLocalFile {
                    infoRow(
                        icon: "doc.fill",
                        label: "File Name",
                        value: url.lastPathComponent
                    )

                    if let fileSize = localFileSizeString {
                        infoRow(
                            icon: "externaldrive.fill",
                            label: "File Size",
                            value: fileSize
                        )
                    }

                    infoRow(
                        icon: "film.stack",
                        label: "Container Format",
                        value: formatDescription
                    )

                    if let modDate = localFileModificationDateString {
                        infoRow(
                            icon: "calendar",
                            label: "Modified",
                            value: modDate
                        )
                    }

                    VStack(alignment: .leading, spacing: AKSpacing.xs) {
                        HStack(spacing: AKSpacing.sm) {
                            Image(systemName: "folder")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(palette.textSecondary)
                                .frame(width: 20)

                            Text("File Path")
                                .font(typography.footnote)
                                .foregroundColor(palette.textSecondary)

                            Spacer()
                        }

                        Text(url.path)
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .foregroundColor(palette.textPrimary.opacity(0.85))
                            .lineLimit(3)
                            .padding(AKSpacing.xs)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .padding(.vertical, AKSpacing.xxxs)
                } else {
                    infoRow(
                        icon: "link",
                        label: "Format / Protocol",
                        value: formatDescription
                    )

                    if let host = url.host {
                        infoRow(
                            icon: "server.rack",
                            label: "Server Host",
                            value: host
                        )
                    }

                    VStack(alignment: .leading, spacing: AKSpacing.xs) {
                        HStack(spacing: AKSpacing.sm) {
                            Image(systemName: "network")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(palette.textSecondary)
                                .frame(width: 20)

                            Text("Stream URL")
                                .font(typography.footnote)
                                .foregroundColor(palette.textSecondary)

                            Spacer()
                        }

                        Text(url.absoluteString)
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .foregroundColor(palette.textPrimary.opacity(0.85))
                            .lineLimit(3)
                            .padding(AKSpacing.xs)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .padding(.vertical, AKSpacing.xxxs)
                }
            }
        }
    }

    // MARK: - Extended Metadata Section

    private var extendedMetadataSection: some View {
        infoCard(title: "Metadata & Details") {
            if let desc = coordinator.metadata.descriptionText, !desc.isEmpty {
                VStack(alignment: .leading, spacing: AKSpacing.xs) {
                    Text("SYNOPSIS")
                        .font(typography.badgeSmall)
                        .foregroundColor(palette.textSecondary.opacity(0.7))

                    Text(desc)
                        .font(typography.caption1)
                        .foregroundColor(palette.textPrimary.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, AKSpacing.xxxs)
            }

            if let genre = coordinator.metadata.genre, !genre.isEmpty {
                infoRow(icon: "tag.fill", label: "Genre", value: genre)
            }

            if let releaseDate = formattedReleaseDate {
                infoRow(icon: "calendar", label: "Release Date", value: releaseDate)
            }

            if let publisher = coordinator.metadata.publisher, !publisher.isEmpty {
                infoRow(icon: "building.2.fill", label: "Publisher", value: publisher)
            }

            if let language = coordinator.metadata.language, !language.isEmpty {
                infoRow(icon: "globe", label: "Language", value: language)
            }

            if let copyright = coordinator.metadata.copyrights, !copyright.isEmpty {
                infoRow(icon: "c.circle", label: "Copyright", value: copyright)
            }
        }
    }

    // MARK: - Reusable Card Components

    private func infoCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AKSpacing.sm) {
            Text(title.uppercased())
                .font(typography.badgeSmall)
                .foregroundColor(palette.textSecondary.opacity(0.7))
                .padding(.horizontal, AKSpacing.xs)

            VStack(spacing: AKSpacing.sm) {
                content()
            }
            .padding(AKSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(palette.glassBorder, lineWidth: 1)
                    )
            )
        }
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: AKSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(palette.textSecondary)
                .frame(width: 20)

            Text(label)
                .font(typography.footnote)
                .foregroundColor(palette.textSecondary)

            Spacer()

            Text(value)
                .font(typography.footnote.weight(.semibold))
                .foregroundColor(palette.textPrimary)
                .lineLimit(1)
        }
        .padding(.vertical, AKSpacing.xxxs)
    }

    private func badgePill(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.18))
            .clipShape(Capsule())
    }

    // MARK: - Local File Helpers

    private var isLocalFile: Bool {
        coordinator.currentMedia?.url.isFileURL ?? false
    }

    private var localFileSizeString: String? {
        guard let url = coordinator.currentMedia?.url, url.isFileURL else { return nil }
        if let res = try? url.resourceValues(forKeys: [.fileSizeKey, .totalFileSizeKey]),
           let size = res.totalFileSize ?? res.fileSize {
            return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
        }
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attrs[.size] as? Int64 {
            return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
        }
        return nil
    }

    private var localFileModificationDateString: String? {
        guard let url = coordinator.currentMedia?.url, url.isFileURL else { return nil }
        if let res = try? url.resourceValues(forKeys: [.contentModificationDateKey]),
           let date = res.contentModificationDate {
            let df = DateFormatter()
            df.dateStyle = .medium
            df.timeStyle = .short
            return df.string(from: date)
        }
        return nil
    }

    private var formatDescription: String {
        guard let url = coordinator.currentMedia?.url else { return "Unknown" }
        let ext = url.pathExtension.uppercased()
        if ext.isEmpty {
            return coordinator.isLive ? "HLS Live Stream" : (url.scheme?.uppercased() ?? "Media")
        }
        switch ext {
        case "M3U8": return "HLS Stream (.m3u8)"
        case "MP4":  return "MPEG-4 Video (.mp4)"
        case "MOV":  return "Apple QuickTime (.mov)"
        case "M4V":  return "Apple Video (.m4v)"
        case "MP3":  return "MPEG Audio Layer 3 (.mp3)"
        case "M4A":  return "Apple Lossless / AAC (.m4a)"
        case "WAV":  return "Waveform Audio (.wav)"
        case "FLAC": return "Free Lossless Audio (.flac)"
        default:     return "\(ext) Media"
        }
    }

    // MARK: - Computed Metadata Properties

    private var resolvedTitle: String {
        if !coordinator.currentTitle.isEmpty {
            return coordinator.currentTitle
        }
        if let title = coordinator.metadata.title, !title.isEmpty {
            return title
        }
        if let url = coordinator.currentMedia?.url, url.isFileURL {
            return url.deletingPathExtension().lastPathComponent
        }
        return "Media Item"
    }

    private var resolvedSubtitle: String {
        if !coordinator.currentSubtitle.isEmpty {
            return coordinator.currentSubtitle
        }
        if let artist = coordinator.metadata.artist, !artist.isEmpty {
            return artist
        }
        if let album = coordinator.metadata.albumTitle, !album.isEmpty {
            return album
        }
        return ""
    }

    private var resolutionString: String {
        let size = coordinator.effectivePresentationSize
        if size.width > 0 && size.height > 0 {
            return "\(Int(size.width)) × \(Int(size.height))"
        }
        return isLocalFile ? "Analyzing Dimensions..." : "Dynamic Adaptive (HLS)"
    }

    private var resolutionTag: String? {
        let size = coordinator.effectivePresentationSize
        if size.width >= 3840 || size.height >= 2160 {
            return "4K UHD"
        } else if size.width >= 1920 || size.height >= 1080 {
            return "1080p FHD"
        } else if size.width >= 1280 || size.height >= 720 {
            return "720p HD"
        } else if size.width > 0 {
            return "SD"
        }
        return nil
    }

    private var aspectRatioString: String {
        let size = coordinator.effectivePresentationSize
        if size.width > 0 && size.height > 0 {
            let gcd = greatestCommonDivisor(Int(size.width), Int(size.height))
            let w = Int(size.width) / gcd
            let h = Int(size.height) / gcd
            if (w == 16 && h == 9) || (w == 4 && h == 3) || (w == 21 && h == 9) {
                return "\(w):\(h)"
            }
            return String(format: "%.2f:1", size.width / size.height)
        }
        return coordinator.aspectRatio.rawValue
    }

    private var progressPercentage: Int {
        guard coordinator.duration > 0 else { return 0 }
        return Int((coordinator.currentTime / coordinator.duration) * 100)
    }

    private var hasExtendedMetadata: Bool {
        let meta = coordinator.metadata
        return !(meta.descriptionText?.isEmpty ?? true)
            || !(meta.genre?.isEmpty ?? true)
            || meta.releaseDate != nil
            || !(meta.publisher?.isEmpty ?? true)
            || !(meta.copyrights?.isEmpty ?? true)
            || !(meta.language?.isEmpty ?? true)
    }

    private var formattedReleaseDate: String? {
        if let date = coordinator.metadata.releaseDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
        return coordinator.metadata.creationDate
    }

    private func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite && !time.isNaN && time > 0 else { return "0:00" }
        let total = Int(time)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    private func greatestCommonDivisor(_ a: Int, _ b: Int) -> Int {
        var x = a
        var y = b
        while y != 0 {
            let t = y
            y = x % y
            x = t
        }
        return max(x, 1)
    }
}
