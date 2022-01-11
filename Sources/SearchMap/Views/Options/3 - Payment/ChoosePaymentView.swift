//
//  File.swift
//  
//
//  Created by GG on 12/02/2021.
//

import UIKit
import ATAGroup
import ActionButton
import PromiseKit
import ATACommonObjects

class ChoosePaymentView: UIView {
    var booking: CreateRide!
    weak var delegate: OptionViewDelegate!
    static func create(booking: inout CreateRide, searchDelegate: SearchRideDelegate, delegate: OptionViewDelegate) -> ChoosePaymentView {
        let ctrl: ChoosePaymentView = Bundle.module.loadNibNamed("ChoosePaymentView", owner: nil)?.first as! ChoosePaymentView
        ctrl.booking = booking
        ctrl.delegate = delegate
        ctrl.viewModel = ChoosePaymentViewModel(searchDelegate: searchDelegate)
        ctrl.loadComponents()
        return ctrl
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = SearchMapController.configuration.palette.background
    }
    
    @IBOutlet weak var title: UILabel!  {
        didSet {
            title.set(text: "Choose payment method".bundleLocale(), for: .title1, textColor: SearchMapController.configuration.palette.mainTexts)
        }
    }
    @IBOutlet weak var shareRideButton: ActionButton!  {
        didSet {
            shareRideButton.actionButtonType = .confirmation
            shareRideButton.setTitle("validate".bundleLocale(), for: .normal)
        }
    }
    
    var viewModel: ChoosePaymentViewModel!
    @IBOutlet weak var collectionView: UICollectionView!  {
        didSet {
            collectionView.delegate = self
            collectionView.register(UINib(nibName: "ChoosePaymentCell", bundle: .module), forCellWithReuseIdentifier: "ChoosePaymentCell")
        }
    }
    var datasource: ChoosePaymentViewModel.DataSource!
    func loadComponents() {
        collectionView.collectionViewLayout = viewModel.layout()
        datasource = viewModel.dataSource(for: collectionView)
        collectionView.dataSource = datasource
        viewModel.applySnapshot(in: datasource)
    }
    
    @IBAction func next() {
        delegate?.next()
    }
}

extension ChoosePaymentView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cellType = datasource.itemIdentifier(for: indexPath), cellType.isActive else { return }
        viewModel.didSelect(itemAt: indexPath)
    }
}

class DynamicHeightCollectionView: UICollectionView {
    override func layoutSubviews() {
        super.layoutSubviews()
        if !__CGSizeEqualToSize(bounds.size, self.intrinsicContentSize) {
            self.invalidateIntrinsicContentSize()
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return contentSize
    }
}
