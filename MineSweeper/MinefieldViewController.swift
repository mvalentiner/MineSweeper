import UIKit

class MinefieldViewController : UIViewController, UICollectionViewDataSource {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

		view.backgroundColor = .darkGray

        layout.itemSize = itemSizeFrom(size: squareSizeFrom(size: view.bounds.size))
        view.addSubview(collectionView)

        sizeConstraint = collectionView.widthAnchor.constraint(equalToConstant: squareSizeFrom(size: view.bounds.size).width)
        NSLayoutConstraint.activate([
            sizeConstraint,
            collectionView.heightAnchor.constraint(equalTo: collectionView.widthAnchor),
            collectionView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            collectionView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ].compactMap { $0 })

        view.addSubview(timerLabel)
		timerLabel.widthAnchor.constraint(equalToConstant: 256).isActive = true
		timerLabel.heightAnchor.constraint(equalToConstant: 24).isActive = true
		timerLabel.leftAnchor.constraint(equalTo: collectionView.leftAnchor).isActive = true
		timerLabel.bottomAnchor.constraint(equalTo: collectionView.topAnchor).isActive = true
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        timerLabel.textColor = .white
		timerLabel.text = format(timeInterval: 0.0)

		// Set up tap gestures for detecting and dispatching single tap and double tap events.
		let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap))
		singleTapGesture.numberOfTapsRequired = 1
		self.collectionView.addGestureRecognizer(singleTapGesture)

		let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
		doubleTapGesture.numberOfTapsRequired = 2
		self.collectionView.addGestureRecognizer(doubleTapGesture)
		
		singleTapGesture.require(toFail: doubleTapGesture)
    }

	// Action to perform on single tap.
	@objc func handleSingleTap(gesture: UITapGestureRecognizer) {
		// Single-tap must toggle the “Flag” emoji (🚩) indicating the presence of a mine under the square.
		let tapLocation = gesture.location(in: self.collectionView)
		guard let indexPath = self.collectionView.indexPathForItem(at: tapLocation) else {
			return
		}
		minefield.flagCell(atIndexPath: indexPath)
	}

	// Action to perform on double tap.
	@objc func handleDoubleTap(gesture: UITapGestureRecognizer) {
		// Double-Tap must open a square.
		let tapLocation = gesture.location(in: self.collectionView)
		guard let indexPath = self.collectionView.indexPathForItem(at: tapLocation) else {
			return
		}
		minefield.openCell(atIndexPath: indexPath)
	}

//	// How do I trigger UIKit to call this? Grrr...
//    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
//        coordinator.animate(
//            alongsideTransition: { (context) in
//                let squareSize = self.squareSizeFrom(size: size)
//                self.sizeConstraint?.constant = squareSize.width
//                self.layout.itemSize = self.itemSizeFrom(size: squareSize)
//                self.layout.invalidateLayout()
//            },
//            completion: { (context) in
//                self.collectionView.reloadData()
//            }
//        )
//    }
//
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentDifficultySelection()
    }

    // MARK: Private

	// MARK: UI
    private var sizeConstraint: NSLayoutConstraint?

    private func squareSizeFrom(size: CGSize) -> CGSize {
        let squareSize = min(size.height, size.width)
        return CGSize(width: squareSize, height: squareSize)
    }

    private func itemSizeFrom(size: CGSize) -> CGSize {
        let numSections = CGFloat(self.numberOfSections(in: self.collectionView))
        let itemSize = squareSizeFrom(size: size).width / numSections
        return CGSize(width: itemSize, height: itemSize)
    }

    private lazy var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        return layout
    }()

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.register(MinefieldCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: MinefieldCollectionViewCell.self))
        return collectionView
    }()

	private lazy var timerLabel : UILabel = {
		let label = UILabel(frame: .zero)
		return label
	}()

	// MARK: Game Engine
	private var minefield = Minefield(forLevel: .beginner)

	private var timer : Timer? = nil

    // MARK: UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
    	// rows
        return minefield.dimension
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    	// columns
        return minefield.dimension
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            	withReuseIdentifier: String(describing: MinefieldCollectionViewCell.self), for: indexPath) as? MinefieldCollectionViewCell else {
            return UICollectionViewCell()
        }

		let cellState = minefield.cellState(atIndexPath: indexPath)
		cell.configureCell(forCellState: cellState)		// UICollectionViewCell is moved out of the UIViewController to fight the Massive-View-Controller problem.
        return cell
    }

	// Action function to update the UI in response to model changes.
	private func updateUI() {
		DispatchQueue.main.async {
			self.collectionView.reloadData()
		}
	}

	// MARK: Private initialization helper functions

    private func presentDifficultySelection() {
    	// Must be able to select game-difficulty level
        let alertController = UIAlertController(title: NSLocalizedString("Choose Difficulty", comment: "Choose a difficulty for the game"),
        	message: nil, preferredStyle: .alert
        )
        alertController.addAction(
            UIAlertAction(title: NSLocalizedString("Beginner", comment: "Easy difficulty"), style: .default) { _ in
				self.initializeGame(forLevel: .beginner)
			}
		)
        alertController.addAction(
            UIAlertAction(title: NSLocalizedString("Intermediate", comment: "Medium difficulty"), style: .default) { _ in
				self.initializeGame(forLevel: .intermediate)
			}
		)
        alertController.addAction(
            UIAlertAction(title: NSLocalizedString("Expert", comment: "Hard difficulty"), style: .default) { _ in
				self.initializeGame(forLevel: .expert)
			}
        )
        present(alertController, animated: true)
    }

	private func initializeGame(forLevel level: Minefield.PlayingLevel) {
		if level != minefield.playingLevel {
			self.minefield = Minefield(forLevel: level)

			// Reload the board
			let squareSize = self.squareSizeFrom(size: view.bounds.size)
			layout.itemSize = itemSizeFrom(size: squareSize)
			layout.invalidateLayout()
			collectionView.reloadData()
		}
		// else the minefield is already initialized

		// Bind actions to ReactiveSwift models
		self.minefield.minefieldCellStates.bind { self.updateUI() }
		self.minefield.gameState.bind { self.showLoseOrWin() }
		self.minefield.playTime.bind { self.updateTimer() }

		timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { (timer) in
			self.minefield.playTime.value += 1.0
		}
	}

	// Action function to update the UI in response to model gameState change.
    private func showLoseOrWin() {
    	timer?.invalidate()
		switch self.minefield.gameState.value {
		case .kaboom:
			let alertController = UIAlertController(title: NSLocalizedString("KABOOM!", comment: ""), message: "Too bad you Loser!", preferredStyle: .alert)
        	present(alertController, animated: true)
			break
		case .win:
			let alertController = UIAlertController(title: NSLocalizedString("YOU WIN!", comment: ""), message: "Woohoo!! You Win!", preferredStyle: .alert)
        	present(alertController, animated: true)
			break
		default:
			break
		}
	}
	
	private func updateTimer() {
		let seconds = self.minefield.playTime.value
		timerLabel.text = format(timeInterval: seconds)
	}
	
	private func format(timeInterval: TimeInterval) -> String {
//		let timeFormatter : DateComponentsFormatter = {
//			let formatter = DateComponentsFormatter()
//			formatter.allowedUnits = [.hour, .minute, .second]
//			return formatter
//		}()
//		return timeFormatter.string(from: timeInterval) ?? ""

		let interval = Int(timeInterval)
		let seconds = interval % 60
		let minutes = (interval / 60) % 60
		let hours = interval / 3600
		let time = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
		return "Time elapsed: \(time)"
	}
}
