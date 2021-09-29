//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2021 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

#if os(Linux) || os(Android)
import Glibc
import CNIOLinux

public enum NIONetlinkSocket {}

/// Represents available netlink multicast groups for a given netlink `NIOBSDSocket.Proto`.
public protocol NIONetlinkMulticastGroupOptionSet: OptionSet where RawValue == UInt32 {}

extension NIONetlinkMulticastGroupOptionSet {
    /// Helper initializer for converting `CInt` group defines to `UInt32`.
    init(_ rawValue: CInt) {
        self.init(rawValue: UInt32(rawValue))
    }
}

// Netlink socket protocols
extension NIOBSDSocket.`Protocol` {
    /// Receives routing and link updates.
    public static let netlinkRoute: NIOBSDSocket.`Protocol` =
                .init(rawValue: NETLINK_ROUTE)
}

// Netlink socket family
extension NIONetlinkSocket {
    /// Specifies the kernel module or netlink group to communicate with.
    public struct Family<Groups: NIONetlinkMulticastGroupOptionSet> {
        public let protocolFamily: NIOBSDSocket.ProtocolFamily = .netlink
        public let `protocol`: NIOBSDSocket.`Protocol`
    }
}

extension NIONetlinkSocket.Family where Groups == NIONetlinkSocket.RoutingGroupOption {
    /// Address for netlink routing and link updates.
    public static let routing: NIONetlinkSocket.Family<Groups> =
        NIONetlinkSocket.Family<Groups>(protocol: .netlinkRoute)
}

extension SocketAddress {
    /// Represents a netlink socket address to which we may want to connect or bind.
    ///
    /// `NIONetlinkSocket.Address` supports netlink socket families via `NIONetlinkSocket.Family` by
    /// associating each `NIOBSDSocket.Proto` to a set of multicast groups that conform to
    /// `NIONetlinkMulticastGroupOptionSet`.
    public struct Netlink<Groups: NIONetlinkMulticastGroupOptionSet> {
        private let _storage: Box<sockaddr_nl>
        public let family: NIONetlinkSocket.Family<Groups>

        public init(family: NIONetlinkSocket.Family<Groups>, port: Int, groups: Groups) {
            var addr = sockaddr_nl()
            addr.nl_family = UInt16(family.protocolFamily.rawValue)
            addr.nl_pad = 0
            addr.nl_pid = UInt32(port)
            addr.nl_groups = groups.rawValue

            self._storage = Box(addr)
            self.family = family
        }

        public func withSockAddr<T>(_ body: (UnsafePointer<sockaddr>, Int) throws -> T) rethrows -> T {
            var address = self._storage.value
            return try address.withSockAddr(body)
        }
    }
}

// Netlink multicast groups
extension NIONetlinkSocket {
    /// Routing multicast group suitable for use in socket options.
    public struct RoutingGroup: RawRepresentable {
        public typealias RawValue = UInt32
        public var rawValue: RawValue
        public init(rawValue: RawValue) {
            self.rawValue = rawValue
        }
    }
}

// Netlink routing multicast group
extension NIONetlinkSocket.RoutingGroup {
    public static let none: NIONetlinkSocket.RoutingGroup =
        NIONetlinkSocket.RoutingGroup(rawValue: RTNLGRP_NONE.rawValue)

    public static let link: NIONetlinkSocket.RoutingGroup =
        NIONetlinkSocket.RoutingGroup(rawValue: RTNLGRP_LINK.rawValue)

    public static let notify: NIONetlinkSocket.RoutingGroup =
        NIONetlinkSocket.RoutingGroup(rawValue: RTNLGRP_NOTIFY.rawValue)

    public static let neighbor: NIONetlinkSocket.RoutingGroup =
        NIONetlinkSocket.RoutingGroup(rawValue: RTNLGRP_NEIGH.rawValue)

    public static let trafficControl: NIONetlinkSocket.RoutingGroup =
        NIONetlinkSocket.RoutingGroup(rawValue: RTNLGRP_TC.rawValue)

    public static let ipv4Address: NIONetlinkSocket.RoutingGroup =
        NIONetlinkSocket.RoutingGroup(rawValue: RTNLGRP_IPV4_IFADDR.rawValue)

    public static let ipv4MulticastRoute: NIONetlinkSocket.RoutingGroup =
        NIONetlinkSocket.RoutingGroup(rawValue: RTNLGRP_IPV4_MROUTE.rawValue)

    public static let ipv4Route: NIONetlinkSocket.RoutingGroup =
        NIONetlinkSocket.RoutingGroup(rawValue: RTNLGRP_IPV4_ROUTE.rawValue)

    public static let ipv4Rule: NIONetlinkSocket.RoutingGroup =
        NIONetlinkSocket.RoutingGroup(rawValue: RTNLGRP_IPV4_RULE.rawValue)

    public static let ipv6Address: NIONetlinkSocket.RoutingGroup =
        NIONetlinkSocket.RoutingGroup(rawValue: RTNLGRP_IPV6_IFADDR.rawValue)

    public static let ipv6MulticastRoute: NIONetlinkSocket.RoutingGroup =
        NIONetlinkSocket.RoutingGroup(rawValue: RTNLGRP_IPV6_MROUTE.rawValue)

    public static let ipv6Route: NIONetlinkSocket.RoutingGroup =
        NIONetlinkSocket.RoutingGroup(rawValue: RTNLGRP_IPV6_ROUTE.rawValue)

    public static let ipv6InterfaceInfo: NIONetlinkSocket.RoutingGroup =
        NIONetlinkSocket.RoutingGroup(rawValue: RTNLGRP_IPV6_IFINFO.rawValue)
}

// Netlink multicast group option sets
extension NIONetlinkSocket {
    public struct RoutingGroupOption: NIONetlinkMulticastGroupOptionSet {
        public let rawValue: UInt32

        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
    }
}

// Netlink routing multicast group option set
extension NIONetlinkSocket.RoutingGroupOption {
    public static let Link = Self(RTMGRP_LINK)
    public static let Notify = Self(RTMGRP_NOTIFY)
    public static let Neighbor = Self(RTMGRP_NEIGH)
    public static let TrafficControl = Self(RTMGRP_TC)

    public static let IPv4Address = Self(RTMGRP_IPV4_IFADDR)
    public static let IPv4MulticastRoute = Self(RTMGRP_IPV4_MROUTE)
    public static let IPv4Route = Self(RTMGRP_IPV4_ROUTE)
    public static let IPv4Rule = Self(RTMGRP_IPV4_ROUTE)

    public static let IPv6Address = Self(RTMGRP_IPV6_IFADDR)
    public static let IPv6MulticastRoute = Self(RTMGRP_IPV6_MROUTE)
    public static let IPv6Route = Self(RTMGRP_IPV6_ROUTE)
    public static let IPv6InterfaceInfo = Self(RTMGRP_IPV6_IFINFO)

    public static let All: Self = [ .Link, .Notify, .Neighbor, .TrafficControl, .IPv4, .IPv6 ]
    public static let IPv4: Self = [ .IPv4Address, .IPv4MulticastRoute, .IPv4Route, .IPv4Rule ]
    public static let IPv6: Self = [ .IPv6Address, .IPv6MulticastRoute, .IPv6Route, .IPv6InterfaceInfo ]
    public static let Address: Self = [ .IPv4Address, .IPv6Address ]
    public static let MulticastRoute: Self = [ .IPv4MulticastRoute, .IPv6MulticastRoute ]
    public static let Route: Self = [ .IPv4Route, .IPv6Route ]
}

extension sockaddr_nl: SockAddrProtocol {
    mutating func withSockAddr<R>(_ body: (UnsafePointer<sockaddr>, Int) throws -> R) rethrows -> R {
        var me = self
        return try withUnsafeBytes(of: &me) { p in
            try body(p.baseAddress!.assumingMemoryBound(to: sockaddr.self), p.count)
        }
    }
}
#endif
