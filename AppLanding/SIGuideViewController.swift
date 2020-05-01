/*
The MIT License (MIT)

Copyright (c) 2020 Mohd Sazid Iqabal

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

import UIKit

// MARK: - Protocols -
@objc public protocol SIGuideViewControllerDelegate{
    @objc optional func siGuideViewCloseButtonPressed()
    @objc optional func siGuideViewNextButtonPressed()
    @objc optional func siGuideViewPrevButtonPressed()
    @objc optional func siGuideViewPageDidChange(_ pageNumber:Int)
}



@objc public protocol SIGuidePage{
    @objc func siGuideViewDidScroll(to:CGFloat, offset:CGFloat)
}


@objc open class SIGuideViewController: UIViewController, UIScrollViewDelegate{

    var seconds = 1000
    var timer = Timer()
    var isTimerRunning = false
    
    func runTimer() {
        timer = Timer.scheduledTimer(timeInterval: 3, target: self,   selector: (#selector(SIGuideViewController.updateTimer)), userInfo: nil, repeats: true)
    }
    
    @objc func updateTimer() {
        seconds -= 1
        if seconds == 0 {
            seconds = 1000
        }
        nextPage()
    }
    
    weak open var delegate:SIGuideViewControllerDelegate?
    @IBOutlet open var pageControl:UIPageControl?
    @IBOutlet open var newPageControll:UIPageControl?
   

    open var currentPage: Int {
        get{
            let page = Int((scrollview.contentOffset.x / view.bounds.size.width))
            return page
        }
    }

    open var currentViewController:UIViewController{
        get{
            let currentPage = self.currentPage;
            return controllers[currentPage];
        }
    }

    open var numberOfPages:Int{
        get {
            return self.controllers.count
        }
    }

    public let scrollview = UIScrollView()
    private var controllers = [UIViewController]()
    private var lastViewConstraint: [NSLayoutConstraint]?

    required public init?(coder aDecoder: NSCoder) {
        scrollview.showsHorizontalScrollIndicator = false
        scrollview.showsVerticalScrollIndicator = false
        scrollview.isPagingEnabled = true
        super.init(coder: aDecoder)
        runTimer()
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    @objc override open func viewDidLoad() {
        super.viewDidLoad()
        pageControl?.addTarget(self, action: #selector(SIGuideViewController.pageControlDidTouch), for: UIControl.Event.touchUpInside)
        scrollview.delegate = self
        scrollview.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(scrollview, at: 0)
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[scrollview]-0-|", options:[], metrics: nil, views: ["scrollview":scrollview] as [String: UIView]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[scrollview]-0-|", options:[], metrics: nil, views: ["scrollview":scrollview] as [String: UIView]))
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);

        updateUI()
        pageControl?.numberOfPages = controllers.count
        pageControl?.currentPage = 0
        newPageControll?.numberOfPages = 3
        newPageControll?.currentPage = 0
    }


    // MARK: - Internal methods -

    // Add the button and connect the action
    @IBAction open func nextPage(){
        if (currentPage + 1) < controllers.count {
            delegate?.siGuideViewNextButtonPressed?()
            gotoPage(currentPage + 1)
        }
        else {
            delegate?.siGuideViewNextButtonPressed?()
            gotoPage(0)
        }
    }

    // Add the button and connect the action
    @IBAction open func prevPage(){
        if currentPage > 0 {
            delegate?.siGuideViewPrevButtonPressed?()
            gotoPage(currentPage - 1)
        }
        else {
            delegate?.siGuideViewPrevButtonPressed?()
            gotoPage(controllers.count-1)
        }
    }

    /// If you want to implement a "skip" button
    /// connect the button to this IBAction and implement the delegate with the skip GuideView
    @IBAction open func close(_ sender: AnyObject) {
        delegate?.siGuideViewCloseButtonPressed?()
    }

   @objc func pageControlDidTouch(){
        if let pc = pageControl{
            gotoPage(pc.currentPage)
        }
    }

    fileprivate func gotoPage(_ page:Int){
        if page < controllers.count{
            var frame = scrollview.frame
            frame.origin.x = CGFloat(page) * frame.size.width
            scrollview.scrollRectToVisible(frame, animated: true)
        }
    }

    open func add(viewController:UIViewController)->Void{
        controllers.append(viewController)
        addChild(viewController)
        viewController.didMove(toParent: self)
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        scrollview.addSubview(viewController.view)
        let metricDict = ["w":viewController.view.bounds.size.width,"h":viewController.view.bounds.size.height]
        let viewsDict: [String: UIView] = ["view":viewController.view, "container": scrollview]

        scrollview.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[view(==container)]", options:[], metrics: metricDict, views: viewsDict))
        scrollview.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[view(==container)]", options:[], metrics: metricDict, views: viewsDict))
        scrollview.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[view]|", options:[], metrics: nil, views: viewsDict))

        if controllers.count == 1{
            scrollview.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[view]", options:[], metrics: nil, views: ["view":viewController.view]))
        }
        else {
            let previousVC = controllers[controllers.count-2]
            if let previousView = previousVC.view {
                scrollview.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[previousView]-0-[view]", options:[], metrics: nil, views: ["previousView":previousView,"view":viewController.view]))
            }

            if let cst = lastViewConstraint {
                scrollview.removeConstraints(cst)
            }
            lastViewConstraint = NSLayoutConstraint.constraints(withVisualFormat: "H:[view]-0-|", options:[], metrics: nil, views: ["view":viewController.view])
            scrollview.addConstraints(lastViewConstraint!)
        }
    }

    fileprivate func updateUI(){
        newPageControll?.currentPage = currentPage%3
        pageControl?.currentPage = currentPage
        delegate?.siGuideViewPageDidChange?(currentPage)
    }

    open func scrollViewDidScroll(_ sv: UIScrollView) {
        for i in 0 ..< controllers.count {
            if let vc = controllers[i] as? SIGuidePage{
                let mx = ((scrollview.contentOffset.x + view.bounds.size.width) - (view.bounds.size.width * CGFloat(i))) / view.bounds.size.width
                if(mx < 2 && mx > -2.0){
                    vc.siGuideViewDidScroll(to:scrollview.contentOffset.x, offset: mx)
                }
            }
        }
    }

    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateUI()
    }

    open func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updateUI()
    }

    fileprivate func adjustOffsetForTransition() {
        let currentPage = self.currentPage

        let popTime = DispatchTime.now() + Double(Int64( Double(NSEC_PER_SEC) * 0.1 )) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: popTime) {
            [weak self] in
            self?.gotoPage(currentPage)
        }
    }

    override open func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        adjustOffsetForTransition()
    }

    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        adjustOffsetForTransition()
    }
}

extension SIGuideViewController {
    func didDismissWithSkipSubscription() {
        timer.invalidate()
        self.delegate?.siGuideViewCloseButtonPressed?()
    }
}
