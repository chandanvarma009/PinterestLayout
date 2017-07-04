//
//  PinterestLayout.swift
//  PinterestLayout
//
//  Created by Roman Sorochak on 7/4/17.
//  Copyright © 2017 MagicLab. All rights reserved.
//

import UIKit


//MARK: CollectionViewLayoutDelegate

public protocol CollectionViewLayoutDelegate {
    
    func collectionView(collectionView: UICollectionView,
                        sizeForSectionHeaderViewForSection section: Int) -> CGSize
    
    func collectionView(collectionView: UICollectionView,
                        heightForImageAtIndexPath indexPath: IndexPath,
                        withWidth: CGFloat) -> CGFloat
    
    func collectionView(collectionView: UICollectionView,
                        heightForAnnotationAtIndexPath indexPath: IndexPath,
                        withWidth: CGFloat) -> CGFloat
}


//MARK: CollectionViewLayoutAttributes

public class PinterestLayoutAttributes: UICollectionViewLayoutAttributes {
    
    public var imageHeight: CGFloat = 0
    
    
    override public func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! PinterestLayoutAttributes
        copy.imageHeight = imageHeight
        return copy
    }
    
    override public func isEqual(_ object: Any?) -> Bool {
        if let attributes = object as? PinterestLayoutAttributes {
            if attributes.imageHeight == imageHeight {
                return super.isEqual(object)
            }
        }
        return false
    }
}


//MARK: CollectionViewLayout

public class PinterestLayout: UICollectionViewLayout {
    
    public var delegate: CollectionViewLayoutDelegate!
    public var numberOfColumns: Int = 1
    public var cellPadding: CGFloat = 0
    
    private var cache = [PinterestLayoutAttributes]()
    private var contentHeight: CGFloat = 0
    private var contentWidth: CGFloat {
        get {
            let bounds = collectionView.bounds
            let insets = collectionView.contentInset
            return bounds.width - insets.left - insets.right
        }
    }
    
    override public var collectionViewContentSize: CGSize {
        get {
            return CGSize(
                width: contentWidth,
                height: contentHeight
            )
        }
    }
    
    override public class var layoutAttributesClass: AnyClass {
        return PinterestLayoutAttributes.self
    }
    
    override public var collectionView: UICollectionView {
        return super.collectionView!
    }
    
    var numberOfSections: Int {
        return collectionView.numberOfSections
    }
    
    func numberOfItems(inSection section: Int) -> Int {
        return collectionView.numberOfItems(inSection: section)
    }
    
    
    override public func prepare() {
        if cache.isEmpty {
            let collumnWidth = contentWidth / CGFloat(numberOfColumns)
            let cellWidth = collumnWidth - (cellPadding * 2)
            
            var xOffsets = [CGFloat]()
            
            for collumn in 0..<numberOfColumns {
                xOffsets.append(CGFloat(collumn) * collumnWidth)
            }
            
            for section in 0..<numberOfSections {
                let numberOfItems = self.numberOfItems(inSection: section)
                
                let headerY = contentHeight
                let headerSize = delegate.collectionView(
                    collectionView: collectionView,
                    sizeForSectionHeaderViewForSection: section
                )
                let headerX = (contentWidth - headerSize.width) / 2
                let headerFrame = CGRect(
                    origin: CGPoint(x: headerX, y: headerY),
                    size: headerSize
                )
                let attributes = PinterestLayoutAttributes(
                    forSupplementaryViewOfKind: UICollectionElementKindSectionHeader,
                    with: IndexPath(item: 0, section: section)
                )
                attributes.frame = headerFrame
                cache.append(attributes)
                
                contentHeight = headerFrame.maxY
                var yOffsets = [CGFloat](
                    repeating: contentHeight,
                    count: numberOfColumns
                )
                
                for item in 0..<numberOfItems {
                    let indexPath = IndexPath(item: item, section: section)
                    
                    let column = yOffsets.index(of: yOffsets.min() ?? 0) ?? 0
                    
                    let imageHeight = delegate.collectionView(
                        collectionView: collectionView,
                        heightForImageAtIndexPath: indexPath,
                        withWidth: cellWidth
                    )
                    let annotationHeight = delegate.collectionView(
                        collectionView: collectionView,
                        heightForAnnotationAtIndexPath: indexPath,
                        withWidth: cellWidth
                    )
                    let cellHeight = cellPadding + imageHeight + annotationHeight + cellPadding
                    
                    let frame = CGRect(
                        x: xOffsets[column],
                        y: yOffsets[column],
                        width: collumnWidth,
                        height: cellHeight
                    )
                    
                    let insetFrame = frame.insetBy(dx: cellPadding, dy: cellPadding)
                    let attributes = PinterestLayoutAttributes(
                        forCellWith: indexPath
                    )
                    attributes.frame = insetFrame
                    attributes.imageHeight = imageHeight
                    cache.append(attributes)
                    
                    contentHeight = max(contentHeight, frame.maxY)
                    yOffsets[column] = yOffsets[column] + cellHeight
                }
            }
        }
    }
    
    override public func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        var layoutAttributes = [UICollectionViewLayoutAttributes]()
        
        for attributes in cache {
            if attributes.frame.intersects(rect) {
                layoutAttributes.append(attributes)
            }
        }
        
        return layoutAttributes
    }
}
