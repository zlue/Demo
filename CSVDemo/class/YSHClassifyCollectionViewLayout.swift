//
//  YSHClassifyCollectionViewLayout.swift
//  Yesho
//
//  Created by innouni on 16/11/25.
//  Copyright © 2016年 innouni. All rights reserved.
//

import UIKit

enum OperatorModel {
    case sub; // 减
    case rate; // 比率
    case height;
}
/// 适用于: 
///    1. 在同一个 section 中 cell 流动布局
///    2. 在不同 section 中 cell 布局不同
class YSHClassifyCollectionViewLayout: UICollectionViewLayout {
    
    /// 下列数组中的值对应每个 section，数组的长度必须不小于section，默认section=2
    
    /// section 中 cell 列数 值
    var colsForSections = [1, 2]
    /// section 中 cell 的水平间距
    var rowMargins: Array<CGFloat> = [0, 5]
    /// section 中 cell 的垂直间距
    var colMargins: Array<CGFloat> = [0, 5]
    /// section 的 外边距
    var sectionInsets = [UIEdgeInsetsMake(0, 0, 0, 0), UIEdgeInsetsMake(5, 5, 5, 5)]
    /// section 中 cell 的宽与高的计算关系及值
    var itemWAndHRelation: Array<(model: OperatorModel, value: CGFloat)> = [(.height, 60), (.rate, 360/630)]
    /// section header 的高
    var headerHeight: Array<CGFloat> = [0, 0, 0]
    
    
    private lazy var attributesArr = [UICollectionViewLayoutAttributes]()
    
    override var collectionViewContentSize: CGSize {
        var height: CGFloat = 0.0
        for section in 0..<(collectionView?.numberOfSections)! {
            let rowsForSection = ((collectionView?.numberOfItems(inSection: section))! + colsForSections[section] - 1) / colsForSections[section]
            let itemW = itemWidth(section: section)
            let itemH = itemHeight(width: itemW, section: section)
            
            height += CGFloat(rowsForSection) * (itemH + rowMargins[section]) - rowMargins[section] + sectionInsets[section].top + sectionInsets[section].bottom + headerHeight[section]
        }
        return CGSize(width: kScreenWidth, height: height)
    }
    
    override func prepare() {
        super.prepare()
        
        attributesArr.removeAll()
        for section in 0..<(collectionView?.numberOfSections)! {
            if headerHeight[section] > 0 {
                let attributes = layoutAttributesForSupplementaryView(ofKind: UICollectionElementKindSectionHeader, at: IndexPath(item: 0, section: section))
                attributesArr.append(attributes!)
            }
            for index in 0..<(collectionView?.numberOfItems(inSection: section))! {
                let indexPath = IndexPath(item: index, section: section)
                let attribute = layoutAttributesForItem(at: indexPath)
                attributesArr.append(attribute!)
            }
        }
    }
    // 计算之前高度
    func maxY(indexPath: IndexPath) -> CGFloat {
        var y: CGFloat = 0
        for section in 0..<indexPath.section {
            let rowsForSection = ((collectionView?.numberOfItems(inSection: section))! + colsForSections[section] - 1) / colsForSections[section]
            let itemW = itemWidth(section: section)
            let itemH = itemHeight(width: itemW, section: section)
            
            y += CGFloat(rowsForSection) * (itemH + rowMargins[section]) - rowMargins[section] + sectionInsets[section].top + sectionInsets[section].bottom + headerHeight[section]
        }
        return y
    }
    // 计算宽
    func itemWidth(section: Int) -> CGFloat {
        let itemW = (kScreenWidth - sectionInsets[section].left - sectionInsets[section].right - CGFloat(colsForSections[section] - 1) * colMargins[section]) / CGFloat(colsForSections[section])
        return itemW
    }
    // 根据宽计算高
    private func itemHeight(width: CGFloat, section: Int) -> CGFloat {
        var height: CGFloat = 0
        switch itemWAndHRelation[section].model {
        case .sub:
            height = width - itemWAndHRelation[section].value
        case .height:
            height = itemWAndHRelation[section].value
        default:
            height = width/itemWAndHRelation[section].value
        }
        return height
    }
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)
        let attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, with: indexPath)
        var y = maxY(indexPath: indexPath)
        y = y > 0 ? y : 0
        attributes.frame = CGRect(x: 0, y: y, width: kScreenWidth, height: headerHeight[indexPath.section])
        return attributes
    }
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        super.layoutAttributesForItem(at: indexPath)
        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        
        var y = maxY(indexPath: indexPath) + headerHeight[indexPath.section]
        let itemW = itemWidth(section: indexPath.section)
        let itemH = itemHeight(width: itemW, section: indexPath.section)
        let currentColForSection = indexPath.row / colsForSections[indexPath.section]
        
        y += CGFloat(currentColForSection) * (itemH + rowMargins[indexPath.section]) + sectionInsets[indexPath.section].top
        
        let x = sectionInsets[indexPath.section].left + CGFloat(indexPath.row % colsForSections[indexPath.section]) * (colMargins[indexPath.section] + itemW)
        attributes.frame = CGRect(x: x, y: y, width: itemW, height: itemH)
        return attributes
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        super.layoutAttributesForElements(in: rect)
        return attributesArr
    }
}
